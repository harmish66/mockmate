# MockMate CLI

A command-line developer tool for MockMate to initialize mocking configurations, validate routes, manage scenarios, and import OpenAPI 3.x specifications.

---

## Installation

Activate the CLI globally using the Dart SDK:

```bash
dart pub global activate mockmate_cli
```

Or run it directly from your project dependencies:

```bash
dart run mockmate_cli <command>
```

---

## Commands

### `mockmate init`

Scaffolds a standard MockMate configuration directory (`mockmate/`) in your project root with a starter `mockmate.json` and a sample JSON fixture:

```bash
mockmate init
```

Use `--force` to reinitialize and overwrite an existing directory:

```bash
mockmate init --force
```

---

### `mockmate validate`

Validates your `mockmate.json` configuration file, checks route definitions, and ensures all JSON fixtures are syntactically valid:

```bash
mockmate validate
```

For automated CI/CD pipelines, output results in machine-readable JSON:

```bash
mockmate validate --json
```

---

### `mockmate import-openapi`

Parses an OpenAPI 3.x specification file and automatically generates mock route definitions and fixture files:

```bash
mockmate import-openapi -i path/to/openapi_spec.json
```

By default, example payloads from the OpenAPI document are saved into `mockmate/fixtures/`. To skip creating fixture files, pass `--no-save-fixtures`.

---

### `mockmate routes`

Lists all registered mock endpoints, their HTTP methods, and response status codes from your configuration:

```bash
mockmate routes
```

---

### `mockmate scenarios`

Displays all available scenarios (standard and custom) and indicates the current default scenario:

```bash
mockmate scenarios
```

---

### `mockmate export`

Bundles your `mockmate.json` and all fixture files into a single, portable JSON export file for easy sharing across team members:

```bash
mockmate export -o mockmate_bundle.json
```

---

### `mockmate report`

Generates a summary report of your mock routes, fixture files, and configuration status:

```bash
# Markdown format (default)
mockmate report

# JSON format
mockmate report -f json
```

---

### `mockmate doctor`

Verifies that your local environment has the required Dart SDK, directory structures, and file permissions:

```bash
mockmate doctor
```

---

## License

BSD-3-Clause License. See the LICENSE file for details.
