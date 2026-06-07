import { createPlottyApp } from "./bootstrap.ts";

const app = createPlottyApp((key) => process.env[key]);

export default {
  fetch: app
};
