echo "~~~ Starting SI Docker Build ~~~"
buildNumber=92

PRODUCT_BUILD_STATUS=$(eval "curl -s https://wso2.org/jenkins/job/products/job/streaming-integrator/$buildNumber/api/json | python3 -c \"import sys, json; print(json.load(sys.stdin)['result'])\"")

echo $PRODUCT_BUILD_STATUS

if [ "${PRODUCT_BUILD_STATUS}" != "SUCCESS" ]
then
    echo "Product build was not successful. Therefore not building docker"
    exit
fi

echo "Wait till artifacts are archived in the product build..."

sleep 120

DISTRIBUTION_NAME=$(eval "curl -s https://wso2.org/jenkins/job/products/job/streaming-integrator/$buildNumber/api/json | python3 -c \"import sys, json; print(json.load(sys.stdin)['artifacts'][1]['fileName'])\"")
echo $DISTRIBUTION_NAME
TEMP=${DISTRIBUTION_NAME%.zip}
DISTRIBUTION_VERSION=${TEMP#wso2si-}

rm -fr docker-build
rm -fr streaming-integrator
rm -f $DISTRIBUTION_NAME

wget --progress=dot:mega https://wso2.org/jenkins/job/products/job/streaming-integrator/$buildNumber/artifact/target/checkout/modules/distribution/target/$DISTRIBUTION_NAME

git clone --depth=50 https://github.com/wso2/streaming-integrator.git
mkdir docker-build
cp streaming-integrator/modules/distribution/src/docker-distribution/filtered/Dockerfile docker-build
unzip -q $DISTRIBUTION_NAME -d docker-build

cd docker-build
DISTRIBUTION_ROOT=wso2si-${DISTRIBUTION_VERSION}

mv $DISTRIBUTION_ROOT wso2si

docker build --pull -t wso2/streaming-integrator:$DISTRIBUTION_VERSION .
docker push wso2/streaming-integrator:$DISTRIBUTION_VERSION

cd ..

rm -r docker-build
rm -r micro-integrator
rm $DISTRIBUTION_NAME

docker image prune -f

echo "~~~ SI Docker Build Finished ~~~"