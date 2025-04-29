# Artisan Ledger Protocol

**Artisan Ledger** is a decentralized smart contract protocol designed to register, organize, manage, and showcase creative works. Built for transparency, collaboration, and provenance, this system empowers creators to retain ownership while enabling thematic curation, access control, and public interaction through viewer responses.

---

## 📜 Overview

The protocol supports:

- **Opus Registry**: Register and manage creative works (titles, creators, classifications, tags).
- **Ownership and Permissions**: Assign, transfer, and revoke viewing rights.
- **Thematic Showcases**: Curate showcases of creative works with optional open collaboration.
- **Personal Collections**: Organize works into public or private collections.
- **Viewer Feedback**: Collect ratings and optional comments from viewers with granted access.

---

## 🧱 Key Components

### Maps and Registries

- `opus-catalog`: Registry of creative works.
- `showcase-catalog`: Organized showcases for thematic grouping.
- `personal-collections`: User-curated collections with visibility settings.
- `viewing-permissions`: Access control for viewing works.
- `viewer-responses`: Ratings and comments for creative works.

### Data Integrity & Validation

- Length and format validation for all inputs.
- Strict ownership verification for actions like updating or removing works.
- Permission tracking with grant/revoke history.

---

## 🚀 Features

- ✅ Decentralized ownership of creative works
- ✅ Showcase creation and public collaboration options
- ✅ Role-based permissions for viewing
- ✅ Responsive system for user feedback and ratings
- ✅ Data-driven metadata management and auditing

---

## 🛠️ Deployment & Usage

This contract is written in [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-overview) and is designed for deployment on the **Stacks blockchain**.

### Requirements

- [Clarinet](https://docs.hiro.so/clarinet) for development/testing
- Stacks wallet to interact with the deployed contract

### Compile

```bash
clarinet check
