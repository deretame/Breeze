const fs = require("fs");
const Minio = require("minio");

const version = process.argv[2];
if (!version) {
  console.error("Usage: node update-tag-to-s3.js <version>");
  process.exit(1);
}

const client = new Minio.Client({
  endPoint: "s3.bitiful.net",
  useSSL: true,
  accessKey: process.env.accessKey,
  secretKey: process.env.secretKey,
});

(async () => {
  try {
    const content = JSON.stringify({
      version,
      updatedAt: new Date().toISOString(),
    });

    fs.writeFileSync("breeze-version.json", content, "utf-8");

    const result = await client.fPutObject(
      "breeze-version",
      "breeze-version.json",
      "./breeze-version.json",
    );
    console.log("上传成功", result.etag, result.versionId);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
})();
