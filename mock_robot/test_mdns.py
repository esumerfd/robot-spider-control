#!/usr/bin/env python3
"""
mDNS Test Utility

Tests if robot-spider.local is resolvable on the network.
"""

import sys
import socket
from zeroconf import Zeroconf, ServiceBrowser, ServiceListener, ServiceInfo
from colorama import Fore, Style, init

init(autoreset=True)

HOSTNAME = "robot-spider.local"


def test_dns_resolution():
    """Test if hostname resolves via standard DNS/mDNS."""
    print(f"\n{Style.BRIGHT}Test 1: DNS/mDNS Resolution{Style.NORMAL}")
    print(f"Attempting to resolve: {HOSTNAME}")

    try:
        # This will try DNS first, then mDNS on macOS
        ip = socket.gethostbyname(HOSTNAME)
        print(f"{Fore.GREEN}✓ SUCCESS:{Style.NORMAL} {HOSTNAME} → {ip}")
        return True
    except socket.gaierror as e:
        print(f"{Fore.RED}✗ FAILED:{Style.NORMAL} Could not resolve {HOSTNAME}")
        print(f"  Error: {e}")
        return False


def test_getaddrinfo():
    """Test using getaddrinfo (more detailed)."""
    print(f"\n{Style.BRIGHT}Test 2: getaddrinfo() lookup{Style.NORMAL}")

    try:
        results = socket.getaddrinfo(HOSTNAME, 8080, socket.AF_INET, socket.SOCK_STREAM)
        print(f"{Fore.GREEN}✓ SUCCESS:{Style.NORMAL} Found {len(results)} result(s)")
        for result in results:
            family, socktype, proto, canonname, sockaddr = result
            ip, port = sockaddr
            print(f"  → {ip}:{port}")
        return True
    except socket.gaierror as e:
        print(f"{Fore.RED}✗ FAILED:{Style.NORMAL} getaddrinfo failed")
        print(f"  Error: {e}")
        return False


class ServiceDiscoveryListener(ServiceListener):
    """Listener for mDNS service discovery."""

    def __init__(self):
        self.found_services = []

    def add_service(self, zc: Zeroconf, type_: str, name: str) -> None:
        info = zc.get_service_info(type_, name)
        if info:
            self.found_services.append((name, info))
            addresses = [socket.inet_ntoa(addr) for addr in info.addresses]
            print(f"{Fore.GREEN}  Found:{Style.NORMAL} {name}")
            print(f"    Addresses: {', '.join(addresses)}")
            print(f"    Port: {info.port}")

    def remove_service(self, zc: Zeroconf, type_: str, name: str) -> None:
        pass

    def update_service(self, zc: Zeroconf, type_: str, name: str) -> None:
        pass


def test_service_discovery():
    """Test mDNS service discovery."""
    print(f"\n{Style.BRIGHT}Test 3: mDNS Service Discovery{Style.NORMAL}")
    print("Searching for _http._tcp.local. services for 3 seconds...")

    zeroconf = Zeroconf()
    listener = ServiceDiscoveryListener()
    browser = ServiceBrowser(zeroconf, "_http._tcp.local.", listener)

    import time
    time.sleep(3)

    browser.cancel()
    zeroconf.close()

    if listener.found_services:
        print(f"{Fore.GREEN}✓ Found {len(listener.found_services)} service(s){Style.NORMAL}")
        return True
    else:
        print(f"{Fore.YELLOW}⚠ No _http._tcp.local. services found{Style.NORMAL}")
        return False


def test_ping():
    """Test if host is pingable."""
    print(f"\n{Style.BRIGHT}Test 4: Ping Test{Style.NORMAL}")

    import subprocess
    try:
        # -c 1 = send 1 packet, -W 2 = wait 2 seconds
        result = subprocess.run(
            ['ping', '-c', '1', '-W', '2', HOSTNAME],
            capture_output=True,
            text=True,
            timeout=3
        )

        if result.returncode == 0:
            print(f"{Fore.GREEN}✓ SUCCESS:{Style.NORMAL} {HOSTNAME} is pingable")
            # Extract the IP from ping output
            for line in result.stdout.split('\n'):
                if 'bytes from' in line:
                    print(f"  {line.strip()}")
            return True
        else:
            print(f"{Fore.RED}✗ FAILED:{Style.NORMAL} Ping failed")
            return False
    except subprocess.TimeoutExpired:
        print(f"{Fore.RED}✗ FAILED:{Style.NORMAL} Ping timed out")
        return False
    except FileNotFoundError:
        print(f"{Fore.YELLOW}⚠ SKIPPED:{Style.NORMAL} ping command not found")
        return False


def main():
    print("=" * 60)
    print(f"{Fore.CYAN}{Style.BRIGHT}mDNS Resolution Test{Style.NORMAL}")
    print("=" * 60)
    print(f"Testing hostname: {Style.BRIGHT}{HOSTNAME}{Style.NORMAL}")
    print("=" * 60)

    # Run all tests
    results = []
    results.append(("DNS/mDNS Resolution", test_dns_resolution()))
    results.append(("getaddrinfo() lookup", test_getaddrinfo()))
    results.append(("mDNS Service Discovery", test_service_discovery()))
    results.append(("Ping Test", test_ping()))

    # Summary
    print("\n" + "=" * 60)
    print(f"{Style.BRIGHT}Test Summary{Style.NORMAL}")
    print("=" * 60)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for test_name, result in results:
        status = f"{Fore.GREEN}PASS{Style.NORMAL}" if result else f"{Fore.RED}FAIL{Style.NORMAL}"
        print(f"  {test_name:.<40} {status}")

    print("=" * 60)
    print(f"Results: {passed}/{total} tests passed")

    if passed == 0:
        print(f"\n{Fore.RED}{Style.BRIGHT}⚠ mDNS is not working!{Style.NORMAL}")
        print("\nPossible issues:")
        print("  1. Mock server is not running")
        print("  2. mDNS/Bonjour service is not running on this system")
        print("  3. Firewall is blocking mDNS (UDP port 5353)")
        print("  4. Testing from Android emulator (mDNS often doesn't work in emulators)")
    elif passed < total:
        print(f"\n{Fore.YELLOW}{Style.BRIGHT}⚠ Partial mDNS functionality{Style.NORMAL}")
    else:
        print(f"\n{Fore.GREEN}{Style.BRIGHT}✓ All mDNS tests passed!{Style.NORMAL}")

    print()
    return 0 if passed > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
