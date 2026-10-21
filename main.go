package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
)

const sigTermWait = 10 * time.Second

var targetProcesses = []string{
	"pveproxy worker (shutdown)",
	"spiceproxy worker (shutdown)",
}

type LogLevel int

const (
	Quiet LogLevel = iota
	Verbose
	Debug
)

var logLevel LogLevel

var dryRun bool

func main() {
	quiet := flag.Bool("q", false, "quiet mode - no output")
	// verbose := flag.Bool("v", false, "verbose mode - show when processes are found and killed")
	debug := flag.Bool("d", false, "debug mode - show all operations including processes analyzed")
	dry := flag.Bool("dry", false, "dry-run mode - don't kill processes, implies debug")
	flag.Parse()

	// Determine log level
	dryRun = *dry
	if dryRun {
		logLevel = Debug
	} else if *quiet {
		logLevel = Quiet
	} else if *debug {
		logLevel = Debug
	} else {
		logLevel = Verbose
	}

	if err := run(); err != nil {
		if logLevel != Quiet {
			log.Fatalf("error: %v", err)
		}
		os.Exit(1)
	}
}

func run() error {
	pids, err := findShutdownWorkers()
	if err != nil {
            return fmt.Errorf("failed to find processes: %w", err)
	}

	if len(pids) == 0 {
		if logLevel == Debug {
			log.Println("no worker (shutdown) processes found")
		}
		return nil
	}

	if logLevel >= Verbose {
		log.Printf("found %d worker (shutdown) process(es): %v", len(pids), pids)
	}

	if dryRun {
		log.Println("dry-run mode: skipping process termination")
		return nil
	}

	// Send SIGTERM first
	for _, pid := range pids {
		if err := syscall.Kill(pid, syscall.SIGTERM); err != nil {
			if logLevel >= Verbose {
				log.Printf("failed to send SIGTERM to PID %d: %v", pid, err)
			}
			continue
		}
		if logLevel >= Verbose {
			log.Printf("sent SIGTERM to PID %d", pid)
		}
	}

	// Wait before sending SIGKILL
	if logLevel == Debug {
		log.Printf("waiting %v before sending SIGKILL", sigTermWait)
	}
	time.Sleep(sigTermWait)

	// Check which processes still exist and send SIGKILL
	for _, pid := range pids {
		if !processExists(pid) {
			if logLevel == Debug {
				log.Printf("PID %d already terminated", pid)
			}
			continue
		}

		if err := syscall.Kill(pid, syscall.SIGKILL); err != nil {
			if logLevel >= Verbose {
				log.Printf("failed to send SIGKILL to PID %d: %v", pid, err)
			}
			continue
		}
		if logLevel >= Verbose {
			log.Printf("sent SIGKILL to PID %d", pid)
		}
	}

	return nil
}

func findShutdownWorkers() ([]int, error) {
	procDir := "/proc"
	entries, err := os.ReadDir(procDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read /proc: %w", err)
	}

	var pids []int
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		// Check if directory name is a number (PID)
		pidStr := entry.Name()
		pid, err := strconv.Atoi(pidStr)
		if err != nil {
			continue
		}

		if logLevel == Debug {
			log.Printf("analyzing PID %d", pid)
		}

		// Read cmdline
		cmdlinePath := filepath.Join(procDir, pidStr, "cmdline")
		cmdlineBytes, err := os.ReadFile(cmdlinePath)
		if err != nil {
			if logLevel == Debug {
				log.Printf("failed to read cmdline for PID %d: %v", pid, err)
			}
			continue
		}

		// cmdline uses null bytes as separators
		cmdline := string(cmdlineBytes)
		cmdline = strings.ReplaceAll(cmdline, "\x00", " ")
		cmdline = strings.TrimSpace(cmdline)

		if logLevel == Debug {
			log.Printf("PID %d cmdline: %s", pid, cmdline)
		}

		for _, target := range targetProcesses {
			if strings.Contains(cmdline, target) {
				pids = append(pids, pid)
				if logLevel == Debug {
					log.Printf("PID %d matches target process %q", pid, target)
				}
				break
			}
		}
	}

	return pids, nil
}

func processExists(pid int) bool {
	process, err := os.FindProcess(pid)
	if err != nil {
        return false
	}

	// Send signal 0 to check if process exists
	err = process.Signal(syscall.Signal(0))
	return err == nil
}
