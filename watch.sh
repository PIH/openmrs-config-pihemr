
# NOTE: this "watches" the directory and rebuilds on changes, so it will run indefinitely until you "Ctrl-C"

mvn clean openmrs-packager:watch -DdelaySeconds=1
