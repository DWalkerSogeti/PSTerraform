## aws_elb_service_account
data "aws_elb_service_account" "root" {}

## aws_lb
resource "aws_lb" "nginx" {
  name               = "globo-web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets ## Updating to ref. new module and all public subnets

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.web_bucket.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = local.common_tags
}

## aws_lb_target_group
resource "aws_lb_target_group" "nginx" {
  name     = "ngnix-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  tags = local.common_tags

}

## aws_lb_listener
resource "aws_lb_listener" "nginx" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }

  tags = local.common_tags

}

## aws_lb_target_group_attachment
## removed 1 and 2 ngnix and created count entry
resource "aws_lb_target_group_attachment" "ngnix" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.nginx.arn
  target_id        = aws_instance.nginx[count.index].id
  port             = 80
}
