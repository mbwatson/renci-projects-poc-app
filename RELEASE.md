#  Release Instructions for the RENCI Matrix Application

This guide walks you through the steps to deploy a new version of this application, from local development to a live Kubernetes environment. We'll be using Git, Docker, and Helm, with most of the complex commands simplified by the project's Makefile.

## Prerequisites

Before beginning, ensure you have the following tools installed and configured:

1. *Git*: For version control.
2. *Docker*: For building and running the application in a container. Make sure the Docker daemon is running.
3. *Helm*: For managing the deployment to Kubernetes.
4. *kubectl*: For interacting with the Kubernetes cluster.
5. *Access to the RENCI Container Registry*: You'll need to be able to push images to containers.renci.org.
6. *Access to the Cluster*: Configure `kubectl` to communicate with Sterling.

## The Release Process

The release process is broken down into six main steps. It's important to follow them in order to ensure a smooth and safe deployment.

---

##### Step 1: Local Development and Testing

Before thinking about a new release, you need to make sure the application is working correctly on your local machine.

1. *Get the Latest Code*: Make sure your main branch is up-to-date with the remote repository:
   - `git checkout main`
   - `git pull origin main`

 2. *Create a Release Branch*: Create a new branch for your release. It's good practice to name it something descriptive, like `release/v0.2.0`.
   - `git checkout -b release/v0.2.0`

 3. *Install Dependencies*: Navigate to the app directory and install dependencies:
   - `cd app`
   - `npm i`

 4. *Run the Development Server*: Start the local development server:
   - `npm run dev` starts the application on http://localhost:5173 (unless configured otherwise). Open this URL in your browser to see the application and test changes.

---

##### Step 2: Prepare the Release with One Command

1. *Run the `set-version` Make target*: From the root of the project, run `make set-version`, and you will be prompted to enter the compelte new version number, _e.g._, `0.2.0`. This single command automatically updates the version number in all the necessary files:
   - `app/package.json`
   - `helm/Chart.yaml`
   - `helm/values.yaml`
   - `.env`

2. *Commit Changes*: Commit the updated files to your release branch.
   - `git add app/package.json helm/Chart.yaml helm/values.yaml .env`
   - `git commit -m "bump version to 0.2.0"`

---


##### Step 3: Build, Push, and Deploy

Now you can build the Docker image, push it to the registry, and deploy it to Kubernetes.

1. *Log in to the Registry*: If you haven't already, log in to the RENCI container registry.
   - `docker login containers.renci.org`

2. *Build and Push the Image*: Use the publish target to build and push the image in one step.
   - `make publish`
   - Then you should be able to verify the new image in containers.renci.org.

3. *Deploy the Application*: Use the helm-up target to deploy the new version to Kubernetes.
   - `make helm-up`

4. *Verify the Deployment*: Check the status of your release and the running pods.
   - `make helm-status`
   - `kubectl get pods -n comms`

---

##### Step 4: Finalize the Release

The final step is to merge changes and tag the release in Git.

1. *Create a Pull Request*: Go to the GitHub repository and create a pull request to merge your release branch (`v0.2.0` to keep the same running example) into `main`.

2. *Merge the Pull Request*: Once the PR is reviewed and approved, merge it.

3. *Tag the Release*: After merging, pull the latest changes to your local main branch and create a Git tag.
   - `git checkout main`
   - `git pull origin main`
   - `git tag -a v0.2.0 -m "Release version 0.2.0"`
   - `git push origin v0.2.0`
