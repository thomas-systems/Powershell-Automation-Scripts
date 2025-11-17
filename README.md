# ⚡ PowerShell Automation Scripts

Welcome!  
This repository contains a collection of **PowerShell automation scripts** That can be used for managing **Microsoft 365, Azure, Entra ID, Intune, Windows servers, and general IT operations**.

The goal of this repo is to provide **clean, reusable, production-ready automation** that saves time, reduces mistakes, and improves workflows.

---

## 📌 Contents

This repository includes scripts for:

### 🔹 Microsoft 365 & Entra ID
- Bulk user creation + assignment  
- License management automation  
- Group membership automation  
- MFA/Authentication method queries  
- User audit & reporting scripts  

### 🔹 Intune / Endpoint Management
- Device inventory reporting  
- Application install automation  
- Compliance status reporting  

### 🔹 Azure
- VM inventory & tagging  
- Resource cleanup automation  
- Monitoring & alerting queries  

### 🔹 Exchange Online
- Mailbox reports  
- Permission audits  
- Shared mailbox automation  

### 🔹 Windows & General Automation
- Bulk CSV imports  
- System information scripts  
- Scheduled task automation  
- Log & event monitor scripts  

---

## 🚀 Requirements

To use these scripts, you’ll need:

- Windows PowerShell 5.1 **or** PowerShell 7+
- Required modules (depending on script):
  - `Microsoft.Graph`
  - `ExchangeOnlineManagement`
  - `AzureAD` (legacy)
  - `Az` (Azure)
  - `IntunePowerShellGraph` (optional)

Most scripts will auto-install modules if missing.

---

## 🛠️ How to Use

Clone the repository:

```sh
git clone https://github.com/thomas-systems/powershell-automation.git
```

## Run a Script
.\Scripts\ScriptHere.ps1
