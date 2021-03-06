#! /bin/bash
echo "Entering script myuserdata"
yum update -y
yum install postgresql docker git jq openssl11 -y

# Configure docker
usermod -a -G docker ec2-user   
# this allows non-root user to run docker cli command but only takes effect after current user session

# Tell docker bridge to use a address pool than 172.17.x.x 
cat << EOF > /etc/docker/daemon.json
{
  "default-address-pools":
  [
    {"base":"10.10.0.0/16","size":24}
  ]
}
EOF

systemctl restart docker
chmod 666 /var/run/docker.sock


# Configure docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


# Load app config
echo "Pulling app configuration."
runuser -l ec2-user -c 'aws configure set region ${aws_region}'
runuser -l ec2-user -c '(echo -n DB_ADDR=;echo ${db_address}) >> .orthanc.env'
runuser -l ec2-user -c '(echo -n DB_PORT=;echo ${db_port}) >> .orthanc.env'
runuser -l ec2-user -c '(echo -n DB_USERNAME=;aws secretsmanager get-secret-value --secret-id ${sec_name} --query SecretString --output text --endpoint-url https://${sm_endpoint} | jq -r .username) >> .orthanc.env'
runuser -l ec2-user -c '(echo -n DB_PASSWORD=;aws secretsmanager get-secret-value --secret-id ${sec_name} --query SecretString --output text --endpoint-url https://${sm_endpoint} | jq -r .password) >> .orthanc.env'
runuser -l ec2-user -c '(echo -n S3_BUCKET=;echo ${s3_bucket}) >> .orthanc.env'
runuser -l ec2-user -c '(echo -n S3_REGION=;echo ${aws_region}) >> .orthanc.env'
runuser -l ec2-user -c 'if ${s3_integration}; then touch .s3_integration; fi'

echo "Leaving script myuserdata"
