#!/usr/bin/env python3
"""
Mock Robot Server for Hexapod Control App Testing

This server simulates a hexapod robot by:
- Running a WebSocket server on port 8080
- Advertising via mDNS as 'robot-spider.local'
- Receiving and logging movement commands
- Optionally sending acknowledgments back to the client
"""

import asyncio
import websockets
import socket
from datetime import datetime
from zeroconf import ServiceInfo, Zeroconf
from colorama import Fore, Style, init

# Initialize colorama for cross-platform colored terminal output
init(autoreset=True)

# Server configuration
WEBSOCKET_PORT = 8080
MDNS_HOSTNAME = "robot-spider.local"
MDNS_SERVICE_TYPE = "_http._tcp.local."

# Valid robot commands
VALID_COMMANDS = {"init", "forward", "backward", "left", "right"}

# Command color mapping for pretty console output
COMMAND_COLORS = {
    "init": Fore.CYAN,
    "forward": Fore.GREEN,
    "backward": Fore.YELLOW,
    "left": Fore.MAGENTA,
    "right": Fore.BLUE,
}


def get_local_ip():
    """Get the local IP address of this machine."""
    try:
        # Create a socket to determine local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception:
        return "127.0.0.1"


def format_timestamp():
    """Return formatted timestamp for logging."""
    return datetime.now().strftime("%H:%M:%S.%f")[:-3]


def log_info(message):
    """Log informational message."""
    print(f"{Fore.WHITE}[{format_timestamp()}] {Style.BRIGHT}INFO:{Style.NORMAL} {message}")


def log_command(command, client_addr):
    """Log received command with color coding."""
    color = COMMAND_COLORS.get(command, Fore.RED)
    timestamp = format_timestamp()
    print(f"{color}[{timestamp}] COMMAND: {Style.BRIGHT}{command.upper()}{Style.NORMAL} from {client_addr}")


def log_error(message):
    """Log error message."""
    print(f"{Fore.RED}[{format_timestamp()}] {Style.BRIGHT}ERROR:{Style.NORMAL} {message}")


def log_warning(message):
    """Log warning message."""
    print(f"{Fore.YELLOW}[{format_timestamp()}] {Style.BRIGHT}WARNING:{Style.NORMAL} {message}")


class MockRobotServer:
    """Mock robot WebSocket server."""

    def __init__(self, send_acks=False):
        """
        Initialize the mock robot server.

        Args:
            send_acks: If True, send acknowledgment messages back to clients
        """
        self.send_acks = send_acks
        self.connected_clients = set()
        self.command_count = 0
        self.zeroconf = None
        self.service_info = None

    async def handle_client(self, websocket):
        """
        Handle a WebSocket client connection.

        Args:
            websocket: The WebSocket connection
        """
        client_addr = f"{websocket.remote_address[0]}:{websocket.remote_address[1]}"
        self.connected_clients.add(websocket)
        log_info(f"{Style.BRIGHT}Client connected: {client_addr}{Style.NORMAL}")
        log_info(f"Total connected clients: {len(self.connected_clients)}")

        try:
            async for message in websocket:
                # Receive and process command
                command = message.strip().lower()

                if command in VALID_COMMANDS:
                    # Valid command received
                    log_command(command, client_addr)
                    self.command_count += 1

                    # Send acknowledgment if enabled
                    if self.send_acks:
                        ack_message = f"OK:{command}"
                        await websocket.send(ack_message)
                        print(f"{Fore.WHITE}  → Sent ACK: {ack_message}")
                else:
                    # Invalid command
                    log_warning(f"Invalid command '{command}' from {client_addr}")
                    if self.send_acks:
                        await websocket.send(f"ERROR:Unknown command '{command}'")

        except websockets.exceptions.ConnectionClosed:
            log_info(f"Client disconnected: {client_addr}")
        except Exception as e:
            log_error(f"Error handling client {client_addr}: {e}")
        finally:
            self.connected_clients.discard(websocket)
            log_info(f"Total connected clients: {len(self.connected_clients)}")

    def register_mdns(self, ip_address):
        """
        Register mDNS service advertisement.

        Args:
            ip_address: The IP address to advertise
        """
        try:
            self.zeroconf = Zeroconf()

            # Create service info
            service_name = f"{MDNS_HOSTNAME.replace('.local', '')}.{MDNS_SERVICE_TYPE}"
            self.service_info = ServiceInfo(
                MDNS_SERVICE_TYPE,
                service_name,
                addresses=[socket.inet_aton(ip_address)],
                port=WEBSOCKET_PORT,
                properties={},
                server=MDNS_HOSTNAME,
            )

            # Register the service
            self.zeroconf.register_service(self.service_info)
            log_info(f"{Style.BRIGHT}mDNS service registered as '{service_name}'{Style.NORMAL}")
            log_info(f"  Hostname: {MDNS_HOSTNAME}")

        except Exception as e:
            log_error(f"Failed to register mDNS service: {e}")
            log_warning("Server will run without mDNS advertisement")

    def unregister_mdns(self):
        """Unregister mDNS service."""
        if self.zeroconf and self.service_info:
            try:
                # Use a short timeout to avoid hanging on shutdown
                import signal

                def timeout_handler(signum, frame):
                    raise TimeoutError("mDNS unregister timeout")

                # Set 2 second timeout for unregistration
                old_handler = signal.signal(signal.SIGALRM, timeout_handler)
                signal.alarm(2)

                try:
                    self.zeroconf.unregister_service(self.service_info)
                    self.zeroconf.close()
                    signal.alarm(0)  # Cancel alarm
                    log_info("mDNS service unregistered")
                finally:
                    signal.signal(signal.SIGALRM, old_handler)

            except TimeoutError:
                log_warning("mDNS unregistration timed out (service will expire naturally)")
            except Exception as e:
                log_warning(f"mDNS cleanup error (service will expire): {e}")

    async def start(self):
        """Start the WebSocket server."""
        local_ip = get_local_ip()
        service_name = f"{MDNS_HOSTNAME.replace('.local', '')}.{MDNS_SERVICE_TYPE}"

        # Print banner
        print("\n" + "=" * 60)
        print(f"{Fore.CYAN}{Style.BRIGHT}Mock Hexapod Robot Server{Style.NORMAL}")
        print("=" * 60)
        log_info(f"Local IP: {Style.BRIGHT}{local_ip}{Style.NORMAL}")
        log_info(f"WebSocket Port: {Style.BRIGHT}{WEBSOCKET_PORT}{Style.NORMAL}")
        log_info(f"mDNS Service Name: {Style.BRIGHT}{service_name}{Style.NORMAL}")
        log_info(f"mDNS Hostname: {Style.BRIGHT}{MDNS_HOSTNAME}{Style.NORMAL}")
        log_info(f"Send Acknowledgments: {Style.BRIGHT}{self.send_acks}{Style.NORMAL}")
        print("=" * 60 + "\n")

        # Register mDNS service
        self.register_mdns(local_ip)

        # Start WebSocket server
        log_info(f"{Style.BRIGHT}WebSocket server starting...{Style.NORMAL}")
        async with websockets.serve(self.handle_client, "0.0.0.0", WEBSOCKET_PORT):
            log_info(f"{Fore.GREEN}{Style.BRIGHT}Server is running! Waiting for connections...{Style.NORMAL}")
            log_info("Press Ctrl+C to stop\n")

            # Keep server running until interrupted
            try:
                await asyncio.Future()  # Run forever
            except asyncio.CancelledError:
                # Clean shutdown requested
                pass

    def shutdown(self):
        """Clean shutdown of the server."""
        log_info("\nShutting down server...")
        self.unregister_mdns()
        log_info(f"Total commands processed: {self.command_count}")
        log_info("Server stopped")


async def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(description="Mock Robot Server for Hexapod Control App")
    parser.add_argument(
        "--acks",
        action="store_true",
        help="Send acknowledgment messages back to clients (default: False)"
    )

    args = parser.parse_args()

    server = MockRobotServer(send_acks=args.acks)

    try:
        await server.start()
    except KeyboardInterrupt:
        pass
    finally:
        server.shutdown()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        # Clean exit on Ctrl+C
        pass
    except asyncio.CancelledError:
        # Suppress cancelled error traceback
        pass
