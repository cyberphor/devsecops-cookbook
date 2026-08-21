## Local Development
Described below are steps you will have to take if you want to edit or develop your own Azure Function application.

**Step 1.** Install the Azure CLI.
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Step 2.** Set your Azure subscription.
```bash
az account set --subscription "Personal"
```

**Step 3.** Install Azure Functions Core Tools.

*Windows*  
[https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?)

*Linux*
```bash
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt update
sudo apt install azure-functions-core-tools-4 -y
```

**Step 4.** Create a Python virtual environment.
```bash
python -m venv venv
```

**Step 4.** Invoke a Python virtual environment.

*Windows*
```bash
.\venv\Scripts\Activate.ps1
```

*Linux*
```bash
source venv/bin/activate
```

**Step 4.** Install the `azure-functions` module and other Python dependencies you may need. 
```bash
python -m pip install -r requirements.txt
```

**Step 5.** Run your code and test it.
```bash
func start --python
```