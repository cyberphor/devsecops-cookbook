import base64
import os

class ContentSecurityPolicyNonceMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        nonce = base64.b64encode(os.urandom(16)).decode('utf-8')
        request.csp_nonce = nonce
        response = self.get_response(request)
        csp = (
            f"default-src 'self'; "
            f"script-src 'self' 'nonce-{nonce}'; "
            f"style-src 'self' 'nonce-{nonce}';"
        )
        response['Content-Security-Policy'] = csp
        return response