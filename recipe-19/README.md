## Recipe 19

## Backend
The steps below describe how the `backend` was created.

**Step 1.** Create a folder called `backend` and change directories to it.
```bash
mkdir backend &&\
cd backend
```

**Step 2.** Create a Python virtual environment called `.venv`.
```bash
python -m venv .venv
```

**Step 3.** Activate the Python virtual environment you just created.
```bash
source .venv/bin/activate
```

**Step 4.** Install a Python web app framework Django.
```bash
pip install django djangorestframework
```

**Step 5.** Create a Django project called `squidfall` (the `django-admin` utility is used for creating and managing projects and apps).
```bash
django-admin startproject squidfall
```

## Database

## Frontend
The steps below describe how the `frontend` was created.

**Step 1.** Create a folder called `frontend` and change directories to it.
```bash
mkdir frontend &&\
cd frontend
```

**Step 2.** Install the Node Version Manager (NVM) if it's not already installed.
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
```

**Step 3.** Copy, paste, and run the commands printed in the previous step.
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
```

**Step 4.** Use NVM to install the latest copy of Node.js (Node), the Node Package Manager (NPM), and Node Package Execute (NPX).
```bash
nvm install node
```

**Step 5.** To confirm what version of Node is installed, enter the command below. 
```bash
node --version
```

You should get output similar to below. 
```
v24.2.0
```

**Step 6.** To confirm what version of NPM and NPX are installed, enter the command below. 
```bash
npm --version
```

You should get output similar to below. 
```
11.3.0
```

**Step 7.** Use NPX to create a new Material UI (MUI) Toolpad Core project called `squidfall`. 
```bash
npx create-toolpad-app@latest squidfall
```

You will be prompted with the following questions.
```
✔ Enter path of directory to bootstrap new app squidfall
✔ Which framework would you like to use? Next.js
✔ Which router would you like to use? Next.js Pages Router
✔ Would you like to enable authentication? no
```

**Step 8.** Create a file called `middleware.ts` within your Toolpad Core project's directory and then, copy and paste the content below to it.
```ts
// Code goes here.
```

**Step 9.** Open the file called `_app.tsx` within the `pages` directory of your Toolpad Core project's directory and then, copy and paste the content below to it.
```ts
// Code goes here.
```

**Step 10.** Open the file called `_document.tsx` within the `pages` directory of your Toolpad Core project's directory and then, copy and paste the content below to it.
```ts
// Code goes here.
```

## References
* [Material UI: Learn how to install Toolpad Core in your local environment.](https://mui.com/toolpad/core/introduction/installation/)
* [Material UI: Content Security Policy](https://mui.com/material-ui/guides/content-security-policy/)
* [Next.js: How to set a Content Security Policy (CSP) for your Next.js application](https://nextjs.org/docs/app/guides/content-security-policy)