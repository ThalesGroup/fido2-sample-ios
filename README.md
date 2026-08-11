# FIDO2 Sample Application

This project is intended to demonstrate the features of the FIDO2 SDK via the sample application.

Please contact the respective Thales representatives to acquire the necessary information.

## Installation

### Setup access to the FIDO2 SDK SPM Repository

The FIDO2 Sample App includes the SDK as SPM private repository. In order to let SPM download it, you need to configure access to the JFrog repository:

1. Make sure that you have access to the Thales CPL IAM Artifactory repository (`thalescpliam.jfrog.io`).
2. Configure the global Swift package registry with the following command:
   ```bash
   swift package-registry set --global https://thalescpliam.jfrog.io/artifactory/api/swift/swift-public
   ```
3. Log in to the Swift package registry:
   ```bash
   swift package-registry login
   ```


