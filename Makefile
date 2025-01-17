include PLUGIN_VERSIONS.sh
export $(shell sed 's/=.*//' PLUGIN_VERSIONS.sh)

create-dir: 
	@rm -rf build/
	@mkdir -p build

main-chart: create-dir
	@helm package -d build helm-chart/splunk-connect-for-kubernetes

logging-chart: create-dir
	@helm package -d build helm-chart/splunk-connect-for-kubernetes/charts/splunk-kubernetes-logging

objects-chart: create-dir
	@helm package -d build helm-chart/splunk-connect-for-kubernetes/charts/splunk-kubernetes-objects

metrics-chart: create-dir
	@helm package -d build helm-chart/splunk-connect-for-kubernetes/charts/splunk-kubernetes-metrics

all-charts: create-dir
	@helm package -d build helm-chart/splunk-connect-for-kubernetes
	@helm package -d build helm-chart/splunk-connect-for-kubernetes/charts/splunk-kubernetes-logging
	@helm package -d build helm-chart/splunk-connect-for-kubernetes/charts/splunk-kubernetes-objects
	@helm package -d build helm-chart/splunk-connect-for-kubernetes/charts/splunk-kubernetes-metrics

version-update:
	@./tools/update_charts_version.sh

build: all-charts

.PHONY: manifests
manifests: main-chart
	@helm template -n default \
	   --set global.splunk.hec.host=172.191.11.89 \
	   --set global.splunk.hec.token=0f0e07ee-7dc3-4abc-8a81-8a7f13ddc51a \
	   --set global.splunk.hec.insecureSSL=false \
	   --set splunk-kubernetes-logging.fullnameOverride="splunk-kubernetes-logging" \
	   --set splunk-kubernetes-metrics.fullnameOverride="splunk-kubernetes-metrics" \
	   --set splunk-kubernetes-objects.fullnameOverride="splunk-kubernetes-objects" \
	   --set splunk-kubernetes-objects.kubernetes.insecureSSL=false \
	   --set splunk-kubernetes-objects.image.tag=$(KUBE_OBJECT_VERSION) \
	   --set splunk-kubernetes-logging.image.tag=$(FLUENTD_HEC_VERSION) \
	   --set splunk-kubernetes-metrics.image.tag=$(K8S_METRICS_VERISION) \
	   --set splunk-kubernetes-metrics.imageAgg.tag=$(K8S_METRICS_AGGR_VERSION) \
	   --set splunk-kubernetes-logging.podSecurityPolicy.create=false \
	   --set splunk-kubernetes-metrics.podSecurityPolicy.create=false \
	   --set splunk-kubernetes-objects.podSecurityPolicy.create=false \
	   $$(ls build/splunk-connect-for-kubernetes-*.tgz) \
	   | ruby tools/gen_manifest.rb manifests

cleanup:
	@rm -rf build

release: version-update manifests
	@cp build/splunk-connect-for-kubernetes-* docs/
	@helm repo index docs
