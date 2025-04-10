import globals from "globals";
import pluginJs from "@eslint/js";

/** @type {import('eslint').Linter.Config[]} */
export default [
  // Apply configuration for all JavaScript files
  { files: ["**/*.js"], languageOptions: { sourceType: "script" } },

  // Define environments
  {
    languageOptions: {
      globals: {
        ...globals.browser,  // Include browser globals
        ...globals.node,     // Include Node.js globals (for `require`, `exports`, etc.)
        importScripts: "readonly",  // Add `importScripts` for service workers
        firebase: "readonly",      // Add `firebase` for Firebase SDK
      },
    },
  },

  // Recommended ESLint rules for JS
  pluginJs.configs.recommended,
];
