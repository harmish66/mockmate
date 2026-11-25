# Contributing

Contributions to MockMate are welcome.

## Verification

Before opening a pull request, run the test and analysis suite:

```bash
dart format .
cd packages/mockmate && dart analyze && dart test
cd ../mockmate_flutter && flutter analyze && flutter test
cd ../mockmate_cli && dart analyze && dart test
```
