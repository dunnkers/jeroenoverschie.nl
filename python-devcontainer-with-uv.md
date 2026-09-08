> ## Content Index
> Fetch the complete content index at: https://jeroenoverschie.nl/llms.txt
> Use this file to discover other available public pages before exploring further.

# Python Devcontainer with uv
- URL: https://jeroenoverschie.nl/python-devcontainer-with-uv/
- Published: 2025-10-02T18:53:36.000Z
- Updated: 2026-09-08T08:04:54.000Z
- Description: Devcontainers are very powerful. So is uv. How do we combine the two?
- Author: Jeroen Overschie

[uv](https://github.com/astral-sh/uv?tab=readme-ov-file#uv) is the new king in Python package manager land. It's fast, comprehensive and by now, well-adopted. [Devcontainers](https://containers.dev) provide a powerful way to create a reproducible development environment, by developing *inside* Docker containers. So, how do we combine the two? To find out, read along.

## How to create a Python + uv Devcontainer

Let's set up our project step-by-step.

### Step 1: Devcontainer.json

1. **Create `devcontainer.json`**  
This is *the* [Devcontainer specification](https://containers.dev/implementors/spec/) telling an editor everything it needs to know about our Devcontainer. Most importantly, we decide which Docker image is to be used. There are official Python images that available on Docker Hub, like [python:3.13](https://hub.docker.com/%5F/python). However, this image is not meant for development. It is a minimal image used to run Python applications. We don't get things like Zsh, Git or a non-root user. For this reason, there are [pre-built Devcontainer images](https://github.com/devcontainers/images/tree/main/src/python) we can use. We will use `mcr.microsoft.com/devcontainers/python:3.13`:  
```json  
{  
    "image: "mcr.microsoft.com/devcontainers/python:3.13"  
}  
```  
`.devcontainer/devcontainer.json`  
... great!
2. **Adding uv**  
To add uv, we can use [Devcontainer Features](https://containers.dev/features):  
    
![Devcontainer features collection](https://jeroenoverschie.nl/content/images/2025/10/Screenshot-2025-10-01-at-15.36.39.png)  
    
Devcontainer Features are pieces of installation code which can be added to your Devcontainer in modular fashion. They are shareable and there is a large collection of features available for us to use. So is the case for uv! There is a [Devcontainer feature for uv](https://github.com/jsburckhardt/devcontainer-features/tree/main/src/uv). We can add uv like so:  
```json  
{  
    "image: "mcr.microsoft.com/devcontainers/python:3.13",  
    "features": {  
        "ghcr.io/jsburckhardt/devcontainer-features/uv:1": {},  
        "ghcr.io/jsburckhardt/devcontainer-features/ruff:1": {}  
    },  
}  
```  
.devcontainer/devcontainer.json  
... great! We also added a [Devcontainer feature for Ruff](https://github.com/jsburckhardt/devcontainer-features/tree/main/src/ruff). Ruff is a fast and widely used tool for Python- linting and formatting. The latest versions of uv and Ruff are installed unless specified otherwise.
3. **Adding VSCode customizations**  
Although Devcontainers are supported by various editors, **VSCode** is the most common. GitHub Codespaces also uses VSCode, meaning we get full [Devcontainer support in GitHub Codespaces](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/adding-a-dev-container-configuration/introduction-to-dev-containers) too.  
We can define extensions to be installed automatically alongside our Devcontainer, by defining [customizations](https://containers.dev/supporting#visual-studio-code):  
```json  
{  
    "image": "mcr.microsoft.com/devcontainers/python:3.13",  
    "features": {  
        "ghcr.io/jsburckhardt/devcontainer-features/uv:1": {},  
        "ghcr.io/jsburckhardt/devcontainer-features/ruff:1": {}  
    },  
    "customizations": {  
        "vscode": {  
            "extensions": [  
                "ms-python.python",  
                "ms-toolsai.jupyter"  
            ]  
        }  
    }  
}  
```  
.devcontainer/devcontainer.json  
... the above installs the VSCode [Python extension](https://marketplace.visualstudio.com/items?itemName=ms-python.python) and [Jupyter extension](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter) automatically when the Devcontainer is opened.

With only just our `.devcontainer.json` file, we can already start the Devcontainer! Install the VSCode [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) and find the blue popup saying **Reopen in Container**:

0:00 

/0:15 

1× 

With our `.devcontainer.json` file we can now open the folder as a Devcontainer in ****VSCode** 🎉.

💡

You can also use the VSCode command palette (CMD+SHIFT+P) and find the command **Reopen in Container.*

Upon opening our Devcontainer, the features we defined earlier are installed for us. Python, uv and ruff are all there:

![](https://jeroenoverschie.nl/content/images/2025/10/Screenshot-2025-10-01-at-20.12.03.png)

Our Devcontainer automatically installs ****Python**, ****uv** and ****ruff**.

Great ✓. Let's continue with our Python project setup.

### Step 2: Python project setup with uv

Now that we have a Devcontainer, let's set up our project *inside* it. 

1. **uv init**  
We can use [uv init](https://docs.astral.sh/uv/concepts/projects/init/#applications) to scaffold a new Python project.  
```shell  
uv init \
  --package \
  --name example_project \
  --description "Example Python Devcontainer project with uv"  
```  
`uv init` can be used to create Python projects. The `--package` argument creates a `src` folder structure.  
... which scaffolds a project structure for us:  
![](https://jeroenoverschie.nl/content/images/2025/10/Screenshot-2025-10-01-at-20.54.19.png)  
A freshly initialised uv project.  
Importantly, a **`pyproject.toml`** file is created. This is the main configuration file for our Python project. Besides configuration, it keeps track of dependencies. Let's add some dependencies.
2. **Adding dependencies**  
We want to test our code, so let's add [pytest](https://pytest.org):  
```shell  
uv add pytest --dev  
```  
Use `uv add` to add new dependencies. `uv` updates `pyproject.toml` for you. See uv docs [Managing dependencies.](https://docs.astral.sh/uv/concepts/projects/dependencies/)  
... upon installing, VSCode also detects a virtual environment being created:  
![](https://jeroenoverschie.nl/content/images/2025/10/Screenshot-2025-10-01-at-21.06.42-1.png)  
VSCode hints the user to select the virtual environment once it is created.  
Select the virtual environment. Notice that after the installation uv has updated our `pyproject.toml` file.  
💡  
If you missed the notification, open the command palette (CMD+SHIFT+P), type **Python: Select Interpreter* and select `./.venv/bin/python`.
3. **Running tests**  
Let's now add a test so we can validate our setup is working.  
![](https://jeroenoverschie.nl/content/images/2025/10/Screenshot-2025-10-01-at-21.17.03.png)  
A simple function and according test.  
... which we can run using:  
```shell  
uv run pytest .  
```  
Use `uv run` to run shell commands with uv. The command ensures its run with the correct venv.  
Resulting in ... a passing test! ✓  
![](https://jeroenoverschie.nl/content/images/2025/10/Screenshot-2025-10-01-at-21.20.24.png)  
Our test passes ✓. The environment is correctly setup.  
Also, feel free to use the VSCode UI:  
![](https://jeroenoverschie.nl/content/images/2025/10/Screenshot-2025-10-01-at-21.23.20.png)  
The VSCode testing UI.  
Awesome! 🎉

## Final setup

At last, our project looks like the following:

![](https://jeroenoverschie.nl/content/images/2025/10/Screenshot-2025-10-02-at-21.47.14.png)

For ease of use, this GitHub repository is available and can be used as a **template**:

[GitHub - dunnkers/python-uv-devcontainer: Python project setup using a Devcontainer and uv.Python project setup using a Devcontainer and uv. Contribute to dunnkers/python-uv-devcontainer development by creating an account on GitHub.![](https://jeroenoverschie.nl/content/images/icon/pinned-octocat-093da3e6fa40.svg)GitHubdunnkers![](https://jeroenoverschie.nl/content/images/thumbnail/python-uv-devcontainer)](https://github.com/dunnkers/python-uv-devcontainer)

A GitHub repository template for a Python uv Devcontainer.

... the repository also comes with some [Extras](https://github.com/dunnkers/python-uv-devcontainer/tree/main?tab=readme-ov-file#extras): a **GitHub Actions workflow** for CI/CD and a **Dockerfile** for production deployments. Enjoy!

## Conclusion

That was an adventure. We set up a **Devcontainer** using a `devcontainer.json` file, we added **uv** and ruff by using Devcontainer features and set up our Python project using `uv init`, `uv add` and `uv run`.

uv is a powerful tool and combining it with a Devcontainer gives us an easy and reproducible project setup. Good luck with your own Python/uv Devcontainer setup! 🍀