#!/usr/bin/env python3
"""Temporary iOS SIMULATOR CI workaround for a Razorpay 1.4.7 SDK mismatch.

The Razorpay iOS plugin refers to RazorpayEventCallback, which is absent from
the resolved native SDK in the current hosted CI build. For the isolated
offline preview only, remove analytics callback registration. Payment success,
failure and wallet delegates are NOT modified. This is NOT a production fix.
"""
import os
from pathlib import Path

cache = Path(os.environ.get('PUB_CACHE', str(Path.home() / '.pub-cache')))
source = cache / 'hosted/pub.dev/razorpay_flutter-1.4.7/ios/Classes/RazorpayDelegate.swift'
if not source.is_file():
    raise SystemExit(f'Fail-closed: expected Razorpay 1.4.7 delegate not found: {source}')

content = source.read_text()
marker = 'ExternalWalletSelectionProtocol, RazorpayEventCallback {'
registration = '''            if let events = self.subscribedAnalyticsEvents, !events.isEmpty {
                razorpay.subscribeToAnalyticsEvents(events, callback: self)
            }'''
for text in (marker, registration):
    if content.count(text) != 1:
        raise SystemExit(f'Fail-closed: expected exactly one Razorpay analytics marker: {text[:55]}')

patched = content.replace(marker, 'ExternalWalletSelectionProtocol {')
patched = patched.replace(registration, '''            // Offline simulator CI only: analytics callback unavailable in
            // resolved native Razorpay SDK; do not register the callback.''')
if patched == content:
    raise SystemExit('Fail-closed: no Razorpay changes applied')
source.write_text(patched)
print('Offline iOS CI: disabled Razorpay analytics callback registration only.')
print('Razorpay payment success/failure and external wallet code remain unchanged.')
