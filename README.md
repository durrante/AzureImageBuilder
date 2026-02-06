# Azure Image Builder - Blog Series Code Repository

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Azure](https://img.shields.io/badge/Azure-Image%20Builder-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/en-us/products/image-builder/)
[![Bicep](https://img.shields.io/badge/IaC-Bicep-blue?logo=microsoft)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

This repository contains all the Infrastructure-as-Code (Bicep) templates and PowerShell scripts referenced in my two-part blog series on automating Azure Virtual Desktop golden images with Azure Image Builder.

## 📝 Blog Series

**Part 1: Laying the Foundation**  
🔗 [https://modernworkspacehub.com/automate-avd-images-azure-image-builder-part-1]  
📅 Published: Feb 2026

**Part 2: Deploying Your Image Template**  
🔗 [Blog post URL - Coming soon]  
📅 Published: [Date TBC]

## 📁 Repository Structure

```
/Part1-Foundation
    ├── main.bicep                      # Main orchestration template
    ├── main.bicepparam                 # Environment-specific parameters
    ├── ResourceGroups.bicep            # Resource group deployment
    ├── AIB.bicep                       # Storage, Compute Gallery, Managed Identity
    ├── CustomRoleDefinition.bicep      # Custom RBAC role
    ├── AssignRGRoles.bicep             # Resource group role assignments
    ├── AssignSubRoles.bicep            # Subscription role assignments
    ├── Register-AzProviders.ps1        # Step 1: Register resource providers
    └── Deploy.ps1                      # Step 2: Deploy infrastructure

/Part2-ImageTemplate
    - Image template definitions and customisation scripts
```

## ⚠️ Important Disclaimer

This code is provided **as-is** without warranty of any kind. It works in my environments, but every organisation is different. 

**You must:**
- ✅ Test thoroughly in a non-production environment first
- ✅ Understand what each script and template does before deploying
- ✅ Customise parameters to suit your environment
- ✅ Review and adjust RBAC permissions based on your security requirements

**I am not responsible for any issues arising from the use of this code in your environment.**

## 🚀 Getting Started

Refer to the accompanying blog posts for detailed explanations and step-by-step deployment instructions.

### Prerequisites

- Azure subscription with Contributor or Owner permissions
- Azure PowerShell module (`Install-Module -Name Az`)
- Basic understanding of Bicep and PowerShell
- Visual Studio Code with Bicep extension (recommended)

## 📋 Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | February 2026 | Initial release - Part 1: Foundation infrastructure |
| 1.1.0 | TBC | Part 2: Image template deployment |

## 🐛 Questions or Issues?

If you spot an issue or have questions, feel free to:
- 💬 Open an issue in this repository
- 📝 Leave a comment on the blog posts
- 🐦 Reach out on Twitter
- 💼 Connect on LinkedIn

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👤 Author

**Alex Durrant**  
Senior EUC Consultant

- 🌐 Blog: [https://modernworkplacehub.com]
- 🐦 X: [https://x.com/ADurrante]
- 💼 LinkedIn: [linkedin.com/in/alexdurrant]

---

**⭐ If you found this helpful, please consider giving this repo a star!**
