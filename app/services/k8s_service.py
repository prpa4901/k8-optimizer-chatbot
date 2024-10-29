from kubernetes import client, config
from app.models.k8s_models import ResourceUsage, ResourceAnalysis, NodeUsage

class K8sService:
    def __init__(self):
        config.load_kube_config()
        self.v1 = client.CoreV1Api()
        self.apps_v1 = client.AppsV1Api()

    def get_resource_usage(self) -> ResourceUsage:
        nodes = self.v1.list_node().items
        usage = ResourceUsage(nodes=[])
        
        for node in nodes:
            node_name = node.metadata.name
            allocatable = node.status.allocatable
            pods = self.v1.list_pod_for_all_namespaces(field_selector=f'spec.nodeName={node_name}').items
            
            cpu_requests = sum(float(c.resources.requests['cpu'].rstrip('m')) / 1000 for pod in pods for c in pod.spec.containers if c.resources.requests and 'cpu' in c.resources.requests)
            memory_requests = sum(int(c.resources.requests['memory'].rstrip('Mi')) for pod in pods for c in pod.spec.containers if c.resources.requests and 'memory' in c.resources.requests)
            
            cpu_usage = cpu_requests / float(allocatable['cpu'])
            memory_usage = memory_requests / int(allocatable['memory'].rstrip('Ki')) * 1024
            
            usage.nodes.append(NodeUsage(
                name=node_name,
                cpu_usage=f"{cpu_usage:.2%}",
                memory_usage=f"{memory_usage:.2%}",
                pod_count=len(pods)
            ))
        
        return usage

    def analyze_resources(self) -> ResourceAnalysis:
        usage = self.get_resource_usage()
        analysis = ResourceAnalysis(recommendations=[])
        
        for node in usage.nodes:
            cpu_usage = float(node.cpu_usage.rstrip('%')) / 100
            memory_usage = float(node.memory_usage.rstrip('%')) / 100
            
            if cpu_usage < 0.5:
                analysis.recommendations.append(f"Node {node.name} CPU usage is low ({node.cpu_usage}). Consider consolidating workloads.")
            elif cpu_usage > 0.8:
                analysis.recommendations.append(f"Node {node.name} CPU usage is high ({node.cpu_usage}). Monitor for potential bottlenecks.")
            
            if memory_usage < 0.5:
                analysis.recommendations.append(f"Node {node.name} memory usage is low ({node.memory_usage}). Review memory requests.")
            elif memory_usage > 0.8:
                analysis.recommendations.append(f"Node {node.name} memory usage is high ({node.memory_usage}). Consider adding more memory or scaling out.")
        
        return analysis