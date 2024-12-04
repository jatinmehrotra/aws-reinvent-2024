import { formatUrl } from "@aws-sdk/util-format-url";
import { HttpRequest } from "@smithy/protocol-http";
import { SignatureV4 } from "@smithy/signature-v4";
import { fromNodeProviderChain } from "@aws-sdk/credential-providers";
import { NODE_REGION_CONFIG_FILE_OPTIONS, NODE_REGION_CONFIG_OPTIONS } from "@smithy/config-resolver";
import { Hash } from "@smithy/hash-node";
import { loadConfig } from "@smithy/node-config-provider";
import pg from "pg";
import assert from "node:assert";
const { Client } = pg;

// Runtime configuration utility
export const getRuntimeConfig = (config) => {
    return {
        runtime: "node",
        sha256: config?.sha256 ?? Hash.bind(null, "sha256"),
        credentials: config?.credentials ?? fromNodeProviderChain(),
        region: config?.region ?? loadConfig(NODE_REGION_CONFIG_OPTIONS, NODE_REGION_CONFIG_FILE_OPTIONS),
        ...config,
    };
};

// Aurora DSQL requires IAM authentication
// This class generates auth tokens signed using AWS Signature Version 4
export class Signer {
    constructor(hostname) {
        const runtimeConfiguration = getRuntimeConfig({});
        this.credentials = runtimeConfiguration.credentials;
        this.hostname = hostname;
        this.region = runtimeConfiguration.region;
        this.sha256 = runtimeConfiguration.sha256;
        this.service = "dsql";
        this.protocol = "https:";
    }

    async getAuthToken() {
        const signer = new SignatureV4({
            service: this.service,
            region: this.region,
            credentials: this.credentials,
            sha256: this.sha256,
        });

        const request = new HttpRequest({
            method: "GET",
            protocol: this.protocol,
            hostname: this.hostname,
            query: { Action: "DbConnectAdmin" },
            headers: { host: this.hostname },
        });

        const presigned = await signer.presign(request, { expiresIn: 3600 });
        return formatUrl(presigned).replace(`${this.protocol}//`, "");
    }
}

// Function to interact with the database: create table, insert data, and read it back
async function interactWithDatabase(token, endpoint) {
    const client = new Client({
        host: endpoint,
        user: "admin",
        password: token,
        database: "postgres",
        port: 5432,
        ssl: { rejectUnauthorized: false },
    });

    await client.connect();
    console.log("[interactWithDatabase] Connected to Aurora DSQL!");

    try {
        // Create a new table
        await client.query(`CREATE TABLE IF NOT EXISTS owner (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(30) NOT NULL,
      city VARCHAR(80) NOT NULL,
      telephone VARCHAR(20)
    )`);

        // Insert some data
        await client.query(
            "INSERT INTO owner(name, city, telephone) VALUES($1, $2, $3)",
            ["John Doe", "Anytown", "555-555-1900"]
        );

        // Check that data is inserted by reading it back
        const result = await client.query("SELECT id, city FROM owner WHERE name='John Doe'");
        assert.strictEqual(result.rows[0].city, "Anytown");
        assert.notStrictEqual(result.rows[0].id, null);
        console.log("[interactWithDatabase] Data successfully inserted and verified!");

        // Clean up by deleting the inserted record
        await client.query("DELETE FROM owner WHERE name='John Doe'");
        console.log("[interactWithDatabase] Cleaned up test data.");
    } catch (error) {
        console.error("[interactWithDatabase] Error:", error);
        throw error;
    } finally {
        await client.end();
    }
}

// Lambda handler
export const handler = async (event) => {
    const endpoint = event.endpoint;
    const signer = new Signer(endpoint);

    try {
        const token = await signer.getAuthToken();
        await interactWithDatabase(token, endpoint);
        return { statusCode: 200, message: "Operation on Aurora DSQL completed successfully" };
    } catch (error) {
        console.error("[handler] Error:", error);
        return { statusCode: 500, message: "Operation on Aurora DSQL failed" };
    }
};
