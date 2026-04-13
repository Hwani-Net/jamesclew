#!/usr/bin/env node
// Stitch Design Audit MCP Server
// Tools: audit_design, audit_design_files

const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const {
  StdioServerTransport,
} = require("@modelcontextprotocol/sdk/server/stdio.js");
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require("@modelcontextprotocol/sdk/types.js");
const fs = require("fs");
const { auditDesignCompliance } = require("./audit");

const server = new Server(
  { name: "stitch-design-audit", version: "1.0.0" },
  { capabilities: { tools: {} } },
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "audit_design",
      description:
        "Audit implementation code against Stitch HTML for ADR-008 design compliance. Checks: No Approximation (border-radius/color), DOM Preservation, Effect Preservation.",
      inputSchema: {
        type: "object",
        properties: {
          stitch_html: {
            type: "string",
            description: "Raw HTML from Stitch get_screen",
          },
          impl_code: {
            type: "string",
            description: "Implementation code (TSX, CSS, or combined)",
          },
        },
        required: ["stitch_html", "impl_code"],
      },
    },
    {
      name: "audit_design_files",
      description:
        "Same as audit_design but reads inputs from file paths instead of inline strings.",
      inputSchema: {
        type: "object",
        properties: {
          stitch_html_path: {
            type: "string",
            description: "Absolute path to Stitch HTML file",
          },
          impl_code_path: {
            type: "string",
            description: "Absolute path to implementation code file (TSX/CSS)",
          },
        },
        required: ["stitch_html_path", "impl_code_path"],
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "audit_design") {
    const { stitch_html, impl_code } = args;
    const result = auditDesignCompliance(stitch_html, impl_code);
    return {
      content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
    };
  }

  if (name === "audit_design_files") {
    const { stitch_html_path, impl_code_path } = args;

    let stitchHtml, implCode;
    try {
      stitchHtml = fs.readFileSync(stitch_html_path, "utf8");
    } catch (e) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              error: `Failed to read stitch_html_path: ${e.message}`,
            }),
          },
        ],
        isError: true,
      };
    }
    try {
      implCode = fs.readFileSync(impl_code_path, "utf8");
    } catch (e) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              error: `Failed to read impl_code_path: ${e.message}`,
            }),
          },
        ],
        isError: true,
      };
    }

    const result = auditDesignCompliance(stitchHtml, implCode);
    return {
      content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
    };
  }

  return {
    content: [
      {
        type: "text",
        text: JSON.stringify({ error: `Unknown tool: ${name}` }),
      },
    ],
    isError: true,
  };
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  process.stderr.write("stitch-design-audit MCP server running\n");
}

main().catch((err) => {
  process.stderr.write(`Fatal: ${err.message}\n`);
  process.exit(1);
});
