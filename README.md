# LinkServiceFAQMerge

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-GPL--3.0-green)
![OTOBO](https://img.shields.io/badge/OTOBO-10.1.x%20%7C%2011.x-orange)

OPM package that adds **11 REST operations** to the OTOBO Generic Interface: link management, ticket merge, agent-level FAQ access, and the service/SLA catalog — all missing from the OTOBO 10.x core.

## Why

OTOBO 10.x ships with Generic Interface operations for tickets and config items, but leaves several common automation needs uncovered:

- **Link management** — no REST operations to list, create, or delete object links.
- **Ticket merge** — no REST endpoint to merge two tickets.
- **FAQ (agent level)** — the built-in FAQ operations are customer-scoped; agents need access to all states.
- **Service & SLA catalog** — no REST operations to query the ITSM service tree or SLA list.

`LinkServiceFAQMerge` fills these gaps without patching the OTOBO core. All operations are registered via SysConfig XML and integrate with any existing Generic Interface webservice.

## Compatibility

| OTOBO version | Status |
|---------------|--------|
| 10.1.x        | ✓ Supported |
| 11.x          | ✓ Supported |

## Operations (11)

| # | Group | Operation | Method | Route | Description |
|---|-------|-----------|--------|-------|-------------|
| 1 | Ticket | TicketMerge | POST | `/TicketMerge` | Merge two tickets (irreversible) |
| 2 | LinkObject | LinkList | GET/POST | `/LinkList` | List links for any object |
| 3 | LinkObject | LinkAdd | POST | `/LinkAdd` | Create a link between two objects |
| 4 | LinkObject | LinkDelete | POST | `/LinkDelete` | Delete a link between two objects |
| 5 | FAQ | FAQSearch | GET/POST | `/FAQSearch` | Search FAQ articles (agent-level, all states) |
| 6 | FAQ | FAQGet | GET | `/FAQGet/:ItemID` | Get a FAQ article (agent-level, no state restriction) |
| 7 | Service | ServiceGet | GET | `/ServiceGet/:ServiceID` | Get service details |
| 8 | Service | ServiceList | GET | `/ServiceList` | List all services |
| 9 | Service | ServiceSearch | GET/POST | `/ServiceSearch` | Search services by name |
| 10 | SLA | SLAGet | GET | `/SLAGet/:SLAID` | Get SLA details |
| 11 | SLA | SLAList | GET | `/SLAList` | List all SLAs |

## Architecture

```
Kernel/
├── Config/Files/XML/
│   └── LinkServiceFAQMerge.xml          ← SysConfig registration for all 11 operations
└── GenericInterface/Operation/
    ├── Extensions/
    │   └── Common.pm                    ← shared base class (ValidateRequiredParams)
    ├── Ticket/
    │   └── TicketMerge.pm               ← extends Ticket::Common
    ├── LinkObject/
    │   ├── LinkList.pm
    │   ├── LinkAdd.pm
    │   └── LinkDelete.pm                ← extend Operation::Common
    ├── FAQ/
    │   ├── FAQSearch.pm
    │   └── FAQGet.pm                    ← extend Operation::Common (soft dep: FAQ package)
    ├── Service/
    │   ├── ServiceGet.pm
    │   ├── ServiceList.pm
    │   └── ServiceSearch.pm             ← extend Operation::Common
    └── SLA/
        ├── SLAGet.pm
        └── SLAList.pm                   ← extend Operation::Common
```

**Pattern:** all operation modules inherit from either `Kernel::GenericInterface::Operation::Common` or `Kernel::GenericInterface::Operation::Ticket::Common`, following the standard OTOBO convention. The internal class `Extensions::Common` provides a shared `ValidateRequiredParams` helper used across all modules. Operations are registered in `LinkServiceFAQMerge.xml` so OTOBO discovers them automatically after a SysConfig rebuild.

**Soft dependencies:** the FAQ and ITSMCore packages are optional. If FAQ is not installed, `FAQSearch` and `FAQGet` return a graceful `.ModuleNotAvailable` error. If ITSMCore is installed, `ServiceGet` automatically includes ITSM fields (Type, Criticality).

## Installation

### Option A: Web — Package Manager (recommended)

1. Download `LinkServiceFAQMerge-1.0.0.opm` from the [latest GitHub Release](https://github.com/oeretana/LinkServiceFAQMerge/releases/latest).
2. In OTOBO: **Admin → Package Manager → Install Package**, upload the `.opm` file.
3. OTOBO rebuilds the configuration automatically on install.

### Option B: CLI

```bash
# Download the package
wget https://github.com/oeretana/LinkServiceFAQMerge/releases/download/v1.0.0/LinkServiceFAQMerge-1.0.0.opm

# Install
sudo -u otobo perl bin/otobo.Console.pl Admin::Package::Install /path/to/LinkServiceFAQMerge-1.0.0.opm

# Verify
sudo -u otobo perl bin/otobo.Console.pl Admin::Package::List | grep LinkService
```

### Post-installation: register the webservice

Installing the OPM makes all 11 operations available to OTOBO's Generic Interface, but does not expose them over HTTP automatically. You must attach them to a Generic Interface webservice — either by importing a ready-made YAML or by adding the operations to an existing webservice.

**Option A — import the included YAML template (quickest):**

1. Clone this repository (or download the source archive from the release page).
2. Go to **Admin → Web Services → Add Web Service → Import**.
3. Upload `development/webservices/LinkServiceFAQMergeConnectorREST.yml`.

OTOBO will create a new webservice named `LinkServiceFAQMergeConnectorREST` (taken from the file name). You can rename it afterwards in **Admin → Web Services → Edit**.

> **Note:** OTOBO's YAML parser rejects non-ASCII characters. If you modify the YAML, keep all description fields ASCII-only or the import will fail with `Loading the YAML string failed`.

**Option B — add operations to an existing webservice:**

Go to **Admin → Web Services → [your webservice] → Edit**, then add each operation individually under the Provider section.

## Uninstallation

```bash
sudo -u otobo perl bin/otobo.Console.pl Admin::Package::Uninstall /path/to/LinkServiceFAQMerge-1.0.0.opm
```

> The uninstall command requires the `.opm` file path, not the package name.

## Building from source

No OTOBO installation required:

```bash
bash bin/build-opm.sh
# Output: dist/LinkServiceFAQMerge-1.0.0.opm
```

The script reads the version from `LinkServiceFAQMerge.sopm`, base64-encodes all source files, and writes a self-contained `.opm` to `dist/`.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Can't load operation backend module` | SysConfig not rebuilt after install | Run `sudo -u otobo perl bin/otobo.Console.pl Maint::Config::Rebuild` |
| `Loading the YAML string failed` | Non-ASCII characters in webservice YAML descriptions | Remove all accented or non-ASCII characters from the YAML before importing |
| `Need GroupName!` when calling an operation | Request uses `GroupID` instead of `GroupName` | Replace `GroupID` with `GroupName` in the request payload |
| Operations do not appear in webservice editor | Package installed but SysConfig not rebuilt | Run `Maint::Config::Rebuild`, then refresh the webservice editor |
| `FAQSearch`/`FAQGet` return `.ModuleNotAvailable` | FAQ package is not installed | Install the OTOBO FAQ package and retry |

## License

GNU General Public License v3.0 — see [COPYING](COPYING).
