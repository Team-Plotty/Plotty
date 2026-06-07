import { createPlottyApp } from "./bootstrap.js";

const app = createPlottyApp((key) => process.env[key]);

export default {
  fetch: app
};
