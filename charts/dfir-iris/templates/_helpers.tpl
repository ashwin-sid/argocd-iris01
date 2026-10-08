{{- define "dfir-iris.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "dfir-iris.labels" -}}
app.kubernetes.io/name: dfir-iris
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: dfir-iris
dfir.example/customer: {{ .Values.customer.id | quote }}
{{- end -}}

{{- define "dfir-iris.secretName" -}}
{{- if .Values.secrets.create -}}
{{ .Release.Name }}-secrets
{{- else -}}
{{ .Values.secrets.existingSecret }}
{{- end -}}
{{- end -}}
