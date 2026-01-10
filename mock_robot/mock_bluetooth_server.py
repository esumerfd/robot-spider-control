#!/usr/bin/env python3
"""
Mock Bluetooth Robot Server for Hexapod Control App Testing

This server simulates a hexapod robot by:
- Creating a Bluetooth Classic RFCOMM server
- Advertising via SPP (Serial Port Profile) as 'robot-spider'
- Receiving and logging movement commands
- Optionally sending acknowledgments back to the client

Requirements:
- PyBluez (bluetooth library)
- colorama (for colored console output)
"""

import sys

try:
    import bluetooth
    from colorama import Fore, Style, init
except ImportError as e:
    print(f"Error: Missing required package: {e}")
    print("\nPlease install required packages:")
    print("  pip3 install pybluez colorama")
    print("\nOn macOS, you may also need to install PyObjC:")
    print("  pip3 install pyobjc")
    sys.exit(1)

from datetime import datetime
import signal

# Initialize colorama for cross-platform colored terminal output
init(autoreset=True)

# Server configuration
SERVER_NAME = "robot-spider"
SERVICE_UUID = "00001101-0000-1000-8000-00805F9B34FB"  # Standard SPP UUID

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


class MockBluetoothRobotServer:
    """Mock robot Bluetooth server."""

    def __init__(self, send_acks=False):
        """
        Initialize the mock Bluetooth robot server.

        Args:
            send_acks: If True, send acknowledgment messages back to clients
        """
        self.send_acks = send_acks
        self.command_count = 0
        self.server_sock = None
        self.client_sock = None
        self.running = False

    def start(self):
        """Start the Bluetooth RFCOMM server."""
        # Print banner
        print("\n" + "=" * 60)
        print(f"{Fore.CYAN}{Style.BRIGHT}Mock Hexapod Bluetooth Robot Server{Style.NORMAL}")
        print("=" * 60)
        log_info(f"Service Name: {Style.BRIGHT}{SERVER_NAME}{Style.NORMAL}")
        log_info(f"Service UUID: {Style.BRIGHT}{SERVICE_UUID}{Style.NORMAL}")
        log_info(f"Send Acknowledgments: {Style.BRIGHT}{self.send_acks}{Style.NORMAL}")
        print("=" * 60 + "\n")

        try:
            # Create Bluetooth socket
            self.server_sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)

            # Bind to any available port
            self.server_sock.bind(("", bluetooth.PORT_ANY))
            port = self.server_sock.getsockname()[1]

            # Start listening
            self.server_sock.listen(1)
            log_info(f"Listening on RFCOMM channel {port}")

            # Advertise service
            bluetooth.advertise_service(
                self.server_sock,
                SERVER_NAME,
                service_id=SERVICE_UUID,
                service_classes=[SERVICE_UUID, bluetooth.SERIAL_PORT_CLASS],
                profiles=[bluetooth.SERIAL_PORT_PROFILE],
            )

            log_info(f"{Fore.GREEN}{Style.BRIGHT}Server is running! Waiting for connections...{Style.NORMAL}")
            log_info("Press Ctrl+C to stop\n")

            self.running = True

            # Accept client connections
            while self.running:
                try:
                    log_info("Waiting for client connection...")
                    self.client_sock, client_info = self.server_sock.accept()
                    client_addr = client_info[0]
                    log_info(f"{Style.BRIGHT}Client connected: {client_addr}{Style.NORMAL}")

                    # Handle client
                    self.handle_client(client_addr)

                except bluetooth.BluetoothError as e:
                    if self.running:
                        log_error(f"Bluetooth error: {e}")
                except KeyboardInterrupt:
                    break

        except bluetooth.BluetoothError as e:
            log_error(f"Failed to start Bluetooth server: {e}")
            log_error("Make sure Bluetooth is enabled and you have the necessary permissions")
            return
        except Exception as e:
            log_error(f"Unexpected error: {e}")
            return
        finally:
            self.shutdown()

    def handle_client(self, client_addr):
        """
        Handle a connected Bluetooth client.

        Args:
            client_addr: The client's Bluetooth address
        """
        try:
            while self.running:
                # Receive data (blocking)
                data = self.client_sock.recv(1024)
                if not data:
                    break

                # Decode command
                command = data.decode('utf-8').strip().lower()

                if command in VALID_COMMANDS:
                    # Valid command received
                    log_command(command, client_addr)
                    self.command_count += 1

                    # Send acknowledgment if enabled
                    if self.send_acks:
                        ack_message = f"OK:{command}"
                        self.client_sock.send(ack_message.encode('utf-8'))
                        print(f"{Fore.WHITE}  → Sent ACK: {ack_message}")
                else:
                    # Invalid command
                    log_warning(f"Invalid command '{command}' from {client_addr}")
                    if self.send_acks:
                        self.client_sock.send(f"ERROR:Unknown command '{command}'".encode('utf-8'))

        except bluetooth.BluetoothError as e:
            log_info(f"Client disconnected: {client_addr}")
        except Exception as e:
            log_error(f"Error handling client {client_addr}: {e}")
        finally:
            if self.client_sock:
                try:
                    self.client_sock.close()
                except:
                    pass
                self.client_sock = None

    def shutdown(self):
        """Clean shutdown of the server."""
        self.running = False
        log_info("\nShutting down server...")

        # Close client socket
        if self.client_sock:
            try:
                self.client_sock.close()
            except:
                pass

        # Stop advertising and close server socket
        if self.server_sock:
            try:
                bluetooth.stop_advertising(self.server_sock)
            except:
                pass
            try:
                self.server_sock.close()
            except:
                pass

        log_info(f"Total commands processed: {self.command_count}")
        log_info("Server stopped")


def signal_handler(sig, frame):
    """Handle Ctrl+C signal."""
    print()  # New line after ^C
    sys.exit(0)


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Mock Bluetooth Robot Server for Hexapod Control App"
    )
    parser.add_argument(
        "--acks",
        action="store_true",
        help="Send acknowledgment messages back to clients (default: False)"
    )

    args = parser.parse_args()

    # Set up signal handler for clean Ctrl+C exit
    signal.signal(signal.SIGINT, signal_handler)

    server = MockBluetoothRobotServer(send_acks=args.acks)
    server.start()


if __name__ == "__main__":
    main()
