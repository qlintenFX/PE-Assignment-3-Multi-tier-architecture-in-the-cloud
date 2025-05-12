import os
from graphviz import Digraph

# Create a new graph
dot = Digraph(comment='Flask CRUD App - Multi-tier Architecture',
              format='png',
              engine='dot')

# Set graph attributes
dot.attr('graph', 
         rankdir='TB', 
         splines='ortho', 
         nodesep='0.8', 
         ranksep='1.0', 
         fontname='Arial')
dot.attr('node', 
         shape='box', 
         style='filled,rounded', 
         color='black', 
         fontname='Arial')
dot.attr('edge', 
         fontname='Arial')

# Define color scheme
colors = {
    'internet': '#D3D3D3',  # Light gray
    'public': '#FFCC99',    # Light orange
    'app': '#99CCFF',       # Light blue
    'db': '#CCFFCC',        # Light green
    'monitoring': '#FFCCFF' # Light purple
}

# Define node and edge styles
dot.attr('node', shape='box', style='filled,rounded', color='black', fontname='Arial')
dot.attr('edge', fontname='Arial')

# Add Internet Gateway and clients
with dot.subgraph(name='cluster_internet') as c:
    c.attr(label='Public Internet', bgcolor=colors['internet'], style='filled,rounded')
    c.node('clients', label='Users', shape='oval')
    c.node('igw', label='Internet\nGateway', shape='diamond')

# Add VPC with public and private subnets
with dot.subgraph(name='cluster_vpc') as vpc:
    vpc.attr(label='VPC (10.0.0.0/16)', bgcolor='white', style='filled,rounded,dashed')
    
    # Public Subnet
    with vpc.subgraph(name='cluster_public') as public:
        public.attr(label='Public Subnets', bgcolor=colors['public'], style='filled,rounded')
        public.node('alb', label='Application\nLoad Balancer', shape='box3d')
        public.node('natgw', label='NAT\nGateway', shape='diamond')
    
    # Private App Subnet
    with vpc.subgraph(name='cluster_app') as app:
        app.attr(label='Private App Subnets', bgcolor=colors['app'], style='filled,rounded')
        app.node('ecs', label='ECS Fargate Cluster\nFlask + Gunicorn', shape='component')
    
    # Private DB Subnet
    with vpc.subgraph(name='cluster_db') as db:
        db.attr(label='Private DB Subnets', bgcolor=colors['db'], style='filled,rounded')
        db.node('rds', label='Amazon RDS\nMySQL', shape='cylinder')

# CloudWatch
with dot.subgraph(name='cluster_monitoring') as monitoring:
    monitoring.attr(label='Monitoring', bgcolor=colors['monitoring'], style='filled,rounded')
    monitoring.node('cloudwatch', label='CloudWatch\nLogs & Metrics', shape='note')

# Add edges
dot.edge('clients', 'igw', label='HTTP/HTTPS')
dot.edge('igw', 'alb', label='HTTP/HTTPS')
dot.edge('alb', 'ecs', label='HTTP')
dot.edge('ecs', 'rds', label='MySQL')
dot.edge('ecs', 'cloudwatch', label='Logs', style='dashed')
dot.edge('ecs', 'natgw', label='Outbound\nTraffic', dir='back')
dot.edge('natgw', 'igw', label='Internet\nAccess', dir='back')

# Render the graph
dot.render('architecture_diagram', cleanup=True)
print("Diagram created: architecture_diagram.png") 