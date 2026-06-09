# Career Objective

I'm a DevOps Engineer with  hands-on experience in AWS, Kubernetes (EKS), CI/CD, Terraform and monitoring tools. I enjoy working with Kubernetes at scale, automating deployments, improving system reliability and solving infrastructure related issues. Looking for a DevOps, Platform or SRE role where I can work across the full lifecycle of an application, from deployment and automation to monitoring and production support.

# Microservice Deployment

This project is a simple Node.js microservice deployment running on AWS EKS. The goal was to build a setup that is easy to deploy, monitor and maintain while following security best practises.

## Overview

The deployment process starts when developers push code to GitHub. Jenkins picks up the changes, runs tests, builds a Docker image, performs a security scan using Trivy and pushes the image to Amazon ECR. Once everything passes, the application is deployed to EKS using Helm charts.

Traffic comes through an AWS ALB and is routed to Kubernetes services and pods. HPA is configured so the application can scale when traffic increases.

For monitoring, Prometheus collects metrics and Grafana is used for dashboards. Logs are collected using Fluent Bit and shipped to Elasticsearch where they can be viewed in Kibana.

## Why I Used Helm

Managing raw Kubernetes manifests becomes difficult as the application grows. Helm makes it easier to manage values like image tags, replica counts and resource limits without changing multiple files. It also provides release history and rollback support which is really helpfull during deployments.

## Security Improvements

A few security controls were added to make the deployment safer:

 Container runs as a non-root user
 Read only root filesystem enabled
 Trivy scans are part of the CI pipeline
 Secrets are stored in Kubernetes Secrets instead of code
 Base image version is pinned instead of using latest

## Monitoring and Logging

The application exposes a `/metrics` endpoint which Prometheus scrapes for metrics. Along with default Node.js metrics, custom request metrics are also collected.

Logs are written in JSON format using Pino and collected by Fluent Bit. From there they are sent to Elasticsearch and visualized in Kibana. This makes troubleshooting much easier when issues happen in production.

## Application Endpoints

 `/` - Basic application status
 `/healthz` - Liveness check
 `/readyz` - Readiness check
`/metrics` - Prometheus metrics

## Tech Stack

AWS EKS, Kubernetes, Docker, Jenkins, Helm, Prometheus, Grafana, Fluent Bit, Elasticsearch and Kibana.
