## Configuration

The following tables lists the configurable parameters of the SNMP Alarm Provider chart and their default values.

Parameter | Description | Default
--------- | ----------- | -------
`ingress.enabled` | If true, an ingress will be created for SNMP Alarm Provider | `true`
`ingress.snmpAgentPort` | SNMP Alarm Provider's ingress SNMP Agent port | `161`
`imageCredentials.repoPath` | SNMP Alarm Provider's image repository | `proj-common-assets-cd/observation/eric-fh-snmp-alarm-provider`
`imageCredentials.pullPolicy` | SNMP Alarm Provider's pull policy  | `IfNotPresent`
`imageCredentials.registry.pullSecret` (DEPRECATED)| To be removed in next major version, please use imageCredentials.pullSecret  | `commented out`
`imageCredentials.pullSecret` | SNMP Alarm Provider's pull secret, overrides global.registry.url | `commented out`
`imageCredentials.registry.url` | SNMP Alarm Provider's image repository, overrides global.registry.url | `commented out`
`images.alarmprovider.name` (DEPRECATED)|To be removed in next major version, please use images.eric-fh-snmp-alarm-provider.name | `eric-fh-snmp-alarm-provider`
`images.alarmprovider.tag`(DEPRECATED)|To be removed in next major version, please use images.eric-fh-snmp-alarm-provider.tag | `2.1.0-<build number>`
`images.eric-fh-snmp-alarm-provider.name` | SNMP Alarm Provider's image name | `eric-fh-snmp-alarm-provider`
`images.eric-fh-snmp-alarm-provider.tag` | SNMP Alarm Provider's image tag | `2.1.0-<build number>`
`global.timezone` | Set the Time zone for SNMP Alarm Provider | `UTC`
`global.registry.pullSecret`(DEPRECATED)|To be removed in next major version, please use global.pullSecret | `commented out`
`global.pullSecret` | SNMP Alarm Provider's pull secret | `commented out`
`global.registry.url` | SNMP Alarm Provider's image repository | `armdocker.rnd.ericsson.se`
`resources.alarmprovider.limits.cpu` | SNMP Alarm Provider's resource limits, CPU | `0.2`
`resources.alarmprovider.limits.memory` | SNMP Alarm Provider's resource limits, memory | `512Mi`
`resources.alarmprovider.requests.cpu` | SNMP Alarm Provider's resource requests, CPU | `0.1`
`resources.alarmprovider.requests.memory` | SNMP Alarm Provider's resource requests, memory | `384Mi`
`service.annotations` | SNMP Alarm Provider's service annotations (additional) | `{}`
`service.clusterIP` | Internal SNMP Alarm Provider's cluster service IP |  `""`
`service.externalIPs`| SNMP Alarm Provider's service external IP addresses | `[]`
`service.loadBalancerIP` | IP address to assign to load balancer (if supported) | `""`
`service.loadBalancerSourceRanges` | List of IP CIDRs allowed access to load balancer (if supported) | `[]`
`service.nodePort` | Port to be used as the service NodePort (ignored if `service.type` is not `NodePort`) | `""`
`service.httpPort` | SNMP Alarm Provider's readiness and liveness probe port | `5006`
`service.snmpAgentPort` | SNMP Alarm Provider's SNMP Agent port | `161`
`service.type` | SNMP Alarm Provider's service type | `ClusterIP`
`service.configMapOverrideName` (DEPRECATED) | Please use service.secretName instead | `""`
`service.debug` | SNMP Alarm Provider debug log enabling (NOTE: deprecated) | `false`
`service.secretName` | SNMP Alarm Provider's secret name | `""`

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install <reponame>/eric-fh-snmp-alarm-provider  \
    --set service.secretName=mysecret
```

Alternatively, a YAML file that specifies the values for those of the above parameters which should be overridden
 can be provided while installing the chart. For example,

```console
$ helm install <reponame>/eric-fh-snmp-alarm-provider  \
    -f values.yaml
```
