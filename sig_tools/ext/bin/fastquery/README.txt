Build Docker Container

1) Compilation of fastquery is operating system dependent. Copy the appropriate Dockerfile_OS file to the name 'Dockerfile'. eg. "cp Dockerfile_Ubuntu14.04 Dockerfile"

1) Change version number in docker_build.sh and docker_push_tags.sh

2) Execute docker_build.sh

3) Push to DockerHub using docker_push_tags.sh

To Compile and Push Fastquery C++ Binary to GitHub

1) Copy 'gitconfig_template' to 'gitconfig'

2) Edit to add Github email and username

3) Copy id_rsa and id_rsa.pub to this directory

4) Copy docker_run_template.sh to docker_run.sh

5) Make docker_run.sh executable "chmod +x docker_run.sh"

6) Edit docker_run.sh to mount local mortar directory
  "-v path/to/mortar/:/cmap/mortar/" 

7) Execute ./docker_run.sh

8) Verify that fastquery binary was deployed to GitHub. (recent commit)
