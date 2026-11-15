export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    // Dependabot incluye tablas y URLs. El formato del título se sigue exigiendo.
    "body-max-line-length": [0],
    "footer-max-line-length": [0],
  },
};

