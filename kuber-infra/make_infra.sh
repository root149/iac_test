cd gitea
bash ./make_gitea.sh
cd ..
echo gitea $(date) >> ../status
cd jenkins
bash ./make_jenkins.sh
cd ..
echo jenkins $(date) >> ../status
cd nexus
bash ./make_nexus.sh
cd ..
echo nexus $(date) >> ../status

