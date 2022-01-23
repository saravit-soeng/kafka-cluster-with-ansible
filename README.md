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

First, run the following script to set up the prerequisite

```bash
ansible-playbook -i inventory/hosts playbooks/setup-prerequisite.yml
```

Generate Certificate authority and truststore using openssl and java keytool for SSL/TLS Security enabled on Kafka cluster
```bash
./scripts/generate-ca-ts.sh
```

Now share the same CA and truststore for all machines, signed the certificate (self-signed), and generate keystore
```bash
ansible-playbook -i inventory/hosts playbooks/generate-ssl-ca.yml
```

__**note__
In case of error with keytool with the created user "kafka", follow the below command as example on all nodes:
```
sudo ln -s /opt/jdk1.8.0_261/bin/keytool /usr/bin/keytool
```


Generate client keystore for kafka cluster connection or testing
```bash
./scripts/generate-client-ks.sh
```

Then copy client keystore to ssl directory of kafka on all hosts for inter-connection or testing
```bash
ansible-playbook -i inventory/hosts playbooks/copy-client-ks-to-all-hosts.yml
```

Now install kafka cluster with ansible script:
```bash
ansible-playbook -i inventory/hosts playbooks/install-kafka.yml
```

Create security credential for admin and client users
```bash
ansible-playbook -i inventory/hosts playbooks/add-security-credentials.yml
```

Generate the kafka connect source for rabbitmq jar file (check in __kafka-connect-rabbitmq-source__ folder, [original source: https://github.com/ibm-messaging/kafka-connect-rabbitmq-source]). We have customed the source code to fit with our design and implementation purpose.

For SSL configuration with RabbitMQ, make sure to copy all RabbitMQ SSL certificates into __kafka-connect-rabbitmq-source/src/main/resources__ folder and then goto that folder, generate a java keystore file (.jks) for storing server certificate with following script

```bash
keytool -import -alias server1 -file server_certificate.pem -keystore rabbitstore.jks
```

Then righ here in the __kafka-connect-rabbitmq-source__ folder, run

```bash
mvn clean package
```

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
