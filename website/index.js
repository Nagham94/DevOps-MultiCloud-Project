import express from 'express';
import helmet from 'helmet';
import compression from 'compression';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname  = dirname(__filename);

const app  = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet({ contentSecurityPolicy: false }));
app.use(compression());
app.use(express.static(join(__dirname, 'public')));

app.get('/health', (req, res) => {
  res.status(200).json({
    status:    'ok',
    timestamp: new Date().toISOString(),
    uptime:    process.uptime()
  });
});

app.get('/api/projects', (req, res) => {
  res.json([
    {
      title:       'DevOps-Multi-Cloud Disaster Recovery',
      description: 'Azure as primary, AWS as DR. Automatic failover via Traffic Manager with sub-60s RTO.',
      tags:        ['Azure', 'AWS', 'Kubernetes', 'Terraform', 'Docker', 'Jenkins'],
      github:      'https://github.com/Nagham94/DevOps-MultiCloud-Project.git'
    },
    {
      title:       'Terraform IaC — AWS',
      description: 'Fully automated AWS infrastructure using reusable modules. VPC, EKS, RDS, and more.',
      tags:        ['Terraform', 'AWS', 'IaC'],
      github:      'https://github.com/Nagham94/aws-labs.git'
    },
    {
      title:       'Graduation Project - Nuvvai Platform',
      description: 'cloud-based platform, Nuvvai Web App, that enables users to upload multi-language web applications which are automatically deployed to AWS using DevOps best practices.',
      tags:        ['AWS', 'Docker', 'Jenkins', 'Prometheus', 'Helm', 'Grafana'],
//      github:      'https://github.com/Nagham94/DevOps-MultiCloud-Project.git'
    },
    {
      title:       'Cloud-Native CI/CD Pipeline & Kubernetes Deployment on AWS',
      description: 'Designed and implemented a complete CI/CD pipeline to deploy a containerized Node.js application on an AWS EKS Kubernetes cluster. Built the pipeline using Jenkins, containerized the application with Docker, and provisioned cloud infrastructure using Terraform (Infrastructure as Code).',
      tags:        ['Jenkins', 'Docker', 'Kubernetes', 'AWS EKS', 'Terraform'],
      github:      'https://github.com/Nagham94/Eyego-task.git'
    }
  ]);
});

app.get('/api/skills', (req, res) => {
  res.json([
    { category: 'Cloud',       items: ['Azure', 'AWS', 'Multi-cloud'] },
    { category: 'Containers',  items: ['Docker', 'Kubernetes', 'EKS'] },
    { category: 'CI/CD',       items: ['Jenkins', 'GitHub Actions'] },
    { category: 'IaC',         items: ['Terraform', 'Ansible'] },
    { category: 'Monitoring',  items: ['Prometheus', 'Grafana'] }
  ]);
});

app.listen(PORT, () => {
  console.log(`Portfolio running at http://localhost:${PORT}`);
});