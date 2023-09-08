# Change log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v3.3.0](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v3.3.0) (2023-09-08)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/v3.2.0...v3.3.0)

### Added

- \(GH-114\) Update supported os versions [\#115](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/115) ([TraGicCode](https://github.com/TraGicCode))
- \(GH-107\) Add puppet 8 support [\#111](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/111) ([TraGicCode](https://github.com/TraGicCode))

## [v3.2.0](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v3.2.0) (2023-09-08)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/v3.1.1...v3.2.0)

### Added

- \(GH-107\) Add puppet 8 support [\#108](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/108) ([TraGicCode](https://github.com/TraGicCode))

## [v3.1.1](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v3.1.1) (2023-01-15)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/v3.1.0...v3.1.1)

### Fixed

- \(GH-101\) Fix documentation for secret lookup using hiera data file interpolation [\#102](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/102) ([TraGicCode](https://github.com/TraGicCode))

## [v3.1.0](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v3.1.0) (2022-09-23)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/v3.0.0...v3.1.0)

### Added

- \(GH-94\) Support for service principal authentication [\#93](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/93) ([kev-in-shu](https://github.com/kev-in-shu))

## [v3.0.0](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v3.0.0) (2022-08-14)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/v2.1.0...v3.0.0)

### Changed

- \(GH-95\) Wrap hiera return in puppet sensitive data type [\#96](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/96) ([TraGicCode](https://github.com/TraGicCode))

## [v2.1.0](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v2.1.0) (2022-08-08)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/v2.0.2...v2.1.0)

### Added

- \(GH-90\) Add windows server 2022 support [\#91](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/91) ([TraGicCode](https://github.com/TraGicCode))

## [v2.0.2](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v2.0.2) (2022-08-04)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/v2.0.1...v2.0.2)

### Fixed

- \(GH-87\) Stop logging secret not found in hiera lookup as warning [\#88](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/88) ([TraGicCode](https://github.com/TraGicCode))

## [v2.0.1](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v2.0.1) (2021-07-15)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/v2.0.0...v2.0.1)

### Fixed

- Fix issue in which confine\_to\_keys must be an array of strings instead of regexp's [\#77](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/77) ([TraGicCode](https://github.com/TraGicCode))

## [v2.0.0](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v2.0.0) (2021-07-14)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/v1.1.2...v2.0.0)

### Changed

- \(GH-69\) Add code and tests for new requires confine\_to\_keys options [\#75](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/75) ([TraGicCode](https://github.com/TraGicCode))

## [v1.1.2](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v1.1.2) (2021-04-29)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/v1.1.1...v1.1.2)

### Fixed

- \(GH-39\) Normalize key names for hiera lookup [\#67](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/67) ([dowlingw](https://github.com/dowlingw))

## [v1.1.1](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v1.1.1) (2021-04-22)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/v1.1.0...v1.1.1)

### Fixed

- \(GH-65\) Managed identity access token not being cached in hiera lookups [\#66](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/66) ([dowlingw](https://github.com/dowlingw))

## [v1.1.0](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/v1.1.0) (2020-02-18)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/1.0.2...v1.1.0)

### Added

- \(GH-58\) Cache Metadata API Token for lifetime of puppet run [\#59](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/59) ([TraGicCode](https://github.com/TraGicCode))

## [1.0.2](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/1.0.2) (2018-12-19)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/1.0.1...1.0.2)

### Fixed

- \(GH-47\) Fix ruby 1.9 issue with uri [\#48](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/48) ([TraGicCode](https://github.com/TraGicCode))

## [1.0.1](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/1.0.1) (2018-12-14)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/1.0.0...1.0.1)

### Fixed

- \(GH-42\) Fix .empty? method missing on uri [\#45](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/45) ([TraGicCode](https://github.com/TraGicCode))
- \(GH-43\) Fix debug message [\#44](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/44) ([TraGicCode](https://github.com/TraGicCode))
- Fix typo in readme.md [\#29](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/29) ([lupyana](https://github.com/lupyana))

## [1.0.0](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/1.0.0) (2018-10-25)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/0.4.0...1.0.0)

### Added

- \(GH-12\) Added Better Unit Tests to puppet function [\#25](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/25) ([TraGicCode](https://github.com/TraGicCode))

## [0.4.0](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/0.4.0) (2018-10-24)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/0.3.0...0.4.0)

### Added

- Add a Hiera backend [\#13](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/13) ([hbuckle](https://github.com/hbuckle))

## [0.3.0](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/0.3.0) (2018-09-26)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/0.2.0...0.3.0)

### Added

- Specify Puppet 6 support [\#8](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/8) ([turbodog](https://github.com/turbodog))

### Fixed

- Change log level from info to debug [\#10](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/10) ([TraGicCode](https://github.com/TraGicCode))
- Add missing comma in readme.md [\#9](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/9) ([TraGicCode](https://github.com/TraGicCode))

## [0.2.0](https://github.com/tragiccode/tragiccode-azure_key_vault/tree/0.2.0) (2018-08-23)

[Full Changelog](https://github.com/tragiccode/tragiccode-azure_key_vault/compare/0.1.0...0.2.0)

### Added

- \(feature\) Update to pdk 1.7.0 [\#2](https://github.com/TraGicCode/tragiccode-azure_key_vault/pull/2) ([TraGicCode](https://github.com/TraGicCode))

## 0.1.0

**Features**
- Implemented `azure_key_vault::secret` function to pull secrets from azure key vault using MSI.

**Bugfixes**

**Known Issues**


\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
