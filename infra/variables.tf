variable "jwt_secret" {
  description = "Segredo de assinatura do JWT, injetado em runtime. NUNCA versionar (controle C5)."
  type        = string
  sensitive   = true
}
