# Contributing to HestiaCP Node.js Integration

First off, thank you for considering contributing to this project! It's people like you that make the open-source community such an amazing place to learn, inspire, and create.

This guide outlines a set of guidelines for contributing to this repository.

---

## Code of Conduct

By participating in this project, you agree to maintain a respectful, welcoming, and collaborative environment for everyone.

---

## How Can I Contribute?

### Reporting Bugs
If you find a bug, please open a new issue. Before doing so, check existing issues to ensure it hasn't been reported yet. When opening a bug report, please include:
- **HestiaCP Version** (e.g., `1.8.12`)
- **Operating System and Version** (e.g., `Ubuntu 24.04 LTS`, `Debian 12`)
- **Node.js Version** (if applicable)
- **Detailed steps to reproduce** the issue
- **Log outputs** (PM2 logs, HestiaCP error logs, or application logs)

### Suggesting Enhancements
We welcome ideas for new features or improvements! Please open an issue explaining:
- The problem you are trying to solve
- The proposed solution or enhancement
- Any alternatives you've considered

### Submitting Pull Requests (PRs)
1. **Fork** the repository and create your branch from `main`.
2. **Set up a test environment** (see below).
3. **Make your changes**:
   - Write clean, commented, and maintainable code.
   - Keep changes focused (don't mix unrelated fixes/features in a single PR).
4. **Test your changes** thoroughly.
5. **Commit your changes** with descriptive commit messages.
6. **Push** to your fork and submit a Pull Request to our `main` branch.

---

## Setting Up a Test Environment

To test changes to the QuickInstall App or the Nginx templates, you will need a running instance of HestiaCP.

> [!WARNING]
> Never test changes directly on a production HestiaCP server. Always use a dedicated development Virtual Machine (VM) or a test VPS.

### Recommended Test Setup
1. Spin up a VM or test server with a clean installation of **Debian 12** or **Ubuntu 22.04/24.04**.
2. Install HestiaCP using the official installer script.
3. Clone your fork of this repository to the test server:
   ```bash
   git clone https://github.com/<your-username>/hestiacp-nodejs.git
   cd hestiacp-nodejs
   ```
4. Run the installer script:
   ```bash
   sudo ./install.sh
   ```
5. Perform manual verification:
   - Create a test domain.
   - Install the Node.js application via **QuickInstall App** in the HestiaCP Web UI.
   - Check if the Nginx templates (`NodeJS.tpl`, `NodeJS.stpl`) are correctly registered and functioning.
   - Verify that the PM2 process starts and restarts as expected using `v-add-pm2-app` or standard PM2 commands.

---

## Project Structure

Before editing, please refer to the structure below:
- `/src/templates/`: Nginx reverse proxy templates.
- `/src/bin/v-add-pm2-app`: The HestiaCP CLI extension to initialize and manage PM2 applications.
- `/src/quickinstall-app/NodeJs/`: PHP classes and assets for the QuickInstall installer in the Web UI.
- `/install.sh`: Script to copy templates, CLI tools, and set up system-wide dependencies.
