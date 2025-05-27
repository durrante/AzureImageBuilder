# Azure Image Builder: Zero to Hero

## Overview

This GitHub repository contains all content and scripts to support building and customising Azure images using Azure Image Builder (AIB).

---

## Example Scenario and Objectives

The following example scenario is based on an organisation using Azure Virtual Desktop (AVD), aiming to simplify image creation and distribution. The objectives include:

- Ensure image lifecycle and validation controls are in place.
- Lock down source content so it is not publicly accessible (e.g. due to licensing or organisational data).
- Use the **Windows 11 22H2 Multi-session + Microsoft 365 Apps Gen2** image from the Azure Marketplace.
- Ensure images support **vTPM** and **Secure Boot** (Trusted Launch).
- Install and verify the following applications:
  - Google Chrome
  - VLC Player
- Configure the image with the following settings:
  - Set default Start Menu pins and taskbar layout
  - Remove a predefined list of Appx packages
  - Set a default wallpaper and lock screen
  - Resolve first-boot slowness (Sysprep fix)
  - Delete the `C:\Temp` folder
  - Remove public desktop shortcuts
- Ensure the image is fully updated (excluding preview patches).
- Distribute the image to the **UK South** region for AVD use.

---

## Prerequisites

Before deploying, review and run the prerequisite script located in the [`prereq`](./prereq) folder. This sets up necessary Azure resources and permissions required by the image builder process.
