# Set Variables
export vRancher=2.12.3
export vCertManager=1.19.1

# Setup Working Directory
if [ -d "workdir" ]; then rm -rf workdir; fi
mkdir workdir && cd workdir

# Download Cert Manager Images
# https://github.com/cert-manager/cert-manager
helm repo add jetstack https://charts.jetstack.io && helm repo update
certManagerImagesMinimal=$(helm template jetstack/cert-manager --version=v${vCertManager} | grep 'image:' | sed 's/"//g' | awk '{ print $2 }' | sed -e "s/^/    - name: /")

# Download Rancher Prime images list
# https://prime.ribs.rancher.io/
curl -sSfL https://prime.ribs.rancher.io/rancher/v${vRancher}/rancher-images.txt -o rancher-images.txt

sed -i "s/^/    - name: registry.rancher.com\//" rancher-images.txt

# Set Rancher Images Variable
rancherImages=$(cat rancher-images.txt)

# Create Hauler Manifest
cat << EOF > ../rancher/rancher-airgap-rancher.yaml
apiVersion: content.hauler.cattle.io/v1
kind: Charts
metadata:
  name: rancher-airgap-charts-rancher
spec:
  charts:
    - name: cert-manager
      repoURL: https://charts.jetstack.io
      version: v${vCertManager}
    - name: rancher
      repoURL: https://charts.rancher.com/server-charts/prime
      version: ${vRancher}
---
apiVersion: content.hauler.cattle.io/v1
kind: Images
metadata:
  name: rancher-airgap-cert-manager-images-rancher
spec:
  images:
${certManagerImagesMinimal}
---
apiVersion: content.hauler.cattle.io/v1
kind: Images
metadata:
  name: rancher-airgap-rancher-images-rancher
spec:
  images:
${rancherImages}
EOF

# cleanup
rm -rf workdir
