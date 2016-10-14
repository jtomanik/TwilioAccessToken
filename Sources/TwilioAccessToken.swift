import JWT

struct TwilioAccessToken {
  var signingKeySid: String
  var accountSid: String
  var secret: String
  var identity: String?
  var ttl: Int
  var grants: [Grant] = []
  var nbf: Int?

  init(signingKeySid: String, accountSid: String, secret: String, ttl: Int = 3600) {
    self.signingKeySid = signingKeySid
    self.accountSid = accountSid
    self.secret = secret
    self.ttl = ttl
  }

  func addGrant(grant: Grant) {
    self.grants.append(grant)
  }

  func toJwt() -> String {
    let now = Int(Date().timeIntervalSince1970)
    let headers = ["cty": "twilio-fpa;v=1"]

    var grantPayload: [String:Any]

    if let identity = identity {
      grantPayload["identity"] = identity
    }

    for grant in self.grants {
      grantPayload[grant.grantKey] = grant.payload
    }

    var payload: [String:Any]
    payload["jti"] = "\(self.signingKeySid)-\(now)"
    payload["iss"] = self.signingKeySid
    payload["sub"] = self.accountSid
    payload["exp"] = now + self.ttl
    payload["grants"] = grantPayload

    if let nbf = self.nbf {
      payload["nbf"] = nbf
    }

    let token = JWT.encode(
      payload,
      additionalHeaders: ["cty": "twilio-fpa;v=1"],
      algorithm: .hs256(self.secret.data(using: .utf8)!)
    )

    return token
  }
}