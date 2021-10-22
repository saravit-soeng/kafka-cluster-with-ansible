# Building Kafka cluster using Ansible

In this setup, we build cluster of 3 machines running Ubuntu server.

We define the inventory hosts as sample below:
```
[cluster]
192.168.0.7
192.168.0.11
192.168.0.12

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

Ansible variables and templates are defined in advanced as in __vars/settings.yml__ and in __templates__ folder, respectively. Some kafka and openssl (for tls/ssl) configuration is configured in __config__ folder.

Now install kafka cluster with ansible script:
```bash
ansible-playbook -i inventory/hosts playbooks/install-kafka.yml
```

Generate Certificate authority and truststore using openssl and java keytool for SSL/TLS Security enabled on Kafka cluster
```bash
./scripts/generate-ca-ts.sh
```

Now share the same CA and truststore for all machines, signed the certificate (self-signed), and generate keystore
```bash
ansible-playbook -i inventory/hosts playbooks/generate-ssl-ca.yml
```

Create security credential for admin and client users
```bash
ansible-playbook -i inventory/hosts playbooks/add-security-credentials.yml
```

Restart the cluster to apply change
```bash
ansible-playbook -i inventory/hosts playbooks/restart-zk-kafka-all-machines.yml
```

Generate client keystore for any usages or testing
```bash
./scripts/generate-client-ks.sh
```

Then copy client keystore for all hosts for testing
```bash
ansible-playbook -i inventory/hosts playbooks/copy-client-ks-to-all-hosts.yml
```

Generate the kafka connect source for rabbitmq jar file (check in __kafka-connect-rabbitmq-source__ folder, [original source: https://github.com/ibm-messaging/kafka-connect-rabbitmq-source]). We have customed the source code to fit with our design and implementation purpose.

Now set up Kafka Connect Source cluster
```bash
ansible-playbook -i inventory/hosts playbooks/setup-kafka-connect-source-cluster.yml
```

Create connector between kafka and rabbitmq with below script from any host of the cluster
```
curl -X POST -H 'Content-Type: application/json' --data @/vagrant/kafka/connectors/rabbitmq-source.json http://192.168.0.7:8083/connectors
```

Sample **rabbitmq-source.json**
```json
{
    "name": "RabbitMQSourceConnector",
    "config": {
        "connector.class": "com.ibm.eventstreams.connect.rabbitmqsource.RabbitMQSourceConnector",
        "tasks.max": "10",
        "kafka.topic": "test",
        "rabbitmq.queue": "test",
        "rabbitmq.hosts": "192.168.0.7,192.168.0.11,192.168.0.12",
        "rabbitmq.port": "5671", 
        "rabbitmq.username": "zzxb",
        "rabbitmq.password": "zzxb12345",
        "rabbitmq.prefetch.count": "500",
        "rabbitmq.automatic.recovery.enabled": "true",
        "rabbitmq.network.recovery.interval.ms": "5000",
        "rabbitmq.topology.recovery.enabled": "true"
    }
}
```
