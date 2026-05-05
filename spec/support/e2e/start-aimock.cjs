const { LLMock } = require("@copilotkit/aimock");
const options = { port: 0 };
if (process.env.DEBUG) {
  options.logLevel = "debug";
}
const mock = new LLMock(options);
mock.start().then(() => {
  process.stdout.write(mock.url + "\n");
});
process.on("SIGTERM", () => {
  mock.stop().then(() => process.exit(0));
});