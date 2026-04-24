const { LLMock } = require("@copilotkit/aimock");
const mock = new LLMock({ port: 0 });
mock.start().then(() => {
  process.stdout.write(mock.url + "\n");
});
process.on("SIGTERM", () => {
  mock.stop().then(() => process.exit(0));
});