package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// LogEntry represents a log entry to be written to file
type LogEntry struct {
	Data       []byte
	Timestamp  time.Time
	ClientAddr string
}

// FileWriter handles sequential writing to files
type FileWriter struct {
	outputDir string
	queue     chan LogEntry
	wg        sync.WaitGroup
}

// NewFileWriter creates a new FileWriter with specified buffer size
func NewFileWriter(outputDir string, bufferSize int) *FileWriter {
	fw := &FileWriter{
		outputDir: outputDir,
		queue:     make(chan LogEntry, bufferSize),
	}
	fw.wg.Add(1)
	go fw.processQueue()
	return fw
}

// QueueData adds data to the write queue
func (fw *FileWriter) QueueData(data []byte, clientAddr string) {
	entry := LogEntry{
		Data:       make([]byte, len(data)),
		Timestamp:  time.Now(),
		ClientAddr: clientAddr,
	}
	copy(entry.Data, data)

	select {
	case fw.queue <- entry:
		// Successfully queued
	default:
		log.Printf("Warning: Write queue is full, dropping message from %s", clientAddr)
	}
}

// Close stops the FileWriter and waits for all pending writes to complete
func (fw *FileWriter) Close() {
	close(fw.queue)
	fw.wg.Wait()
}

// processQueue processes the write queue sequentially
func (fw *FileWriter) processQueue() {
	defer fw.wg.Done()

	for entry := range fw.queue {
		if err := fw.writeToFile(entry); err != nil {
			log.Printf("Error writing to file: %v", err)
		} else {
			log.Printf("Received from %s: %s", entry.ClientAddr, string(entry.Data))
		}
	}
}

// writeToFile writes a log entry to the appropriate file
func (fw *FileWriter) writeToFile(entry LogEntry) error {
	// Generate filename based on timestamp
	filename := entry.Timestamp.Format("20060102") + ".txt"
	filepath := filepath.Join(fw.outputDir, filename)

	// Open file in append mode, create if it doesn't exist
	file, err := os.OpenFile(filepath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("failed to open file %s: %v", filepath, err)
	}
	defer file.Close()

	// Write timestamp and data
	timestamp := entry.Timestamp.Format("2006-01-02 15:04:05")
	line := fmt.Sprintf("[%s] %s\n", timestamp, string(entry.Data))

	if _, err := file.WriteString(line); err != nil {
		return fmt.Errorf("failed to write to file: %v", err)
	}

	return nil
}

func main() {
	// Parse command line arguments with aliases
	var port, outputDir string
	var queueSize int

	// Port flags with alias
	flag.StringVar(&port, "port", "8080", "Port to listen on")
	flag.StringVar(&port, "p", "8080", "Port to listen on (shorthand)")

	// Output directory flags with alias
	flag.StringVar(&outputDir, "output", "./logs", "Output directory for log files")
	flag.StringVar(&outputDir, "o", "./logs", "Output directory for log files (shorthand)")

	// Queue size flags with alias
	flag.IntVar(&queueSize, "queue-size", 1000, "Size of the write queue buffer")
	flag.IntVar(&queueSize, "q", 1000, "Size of the write queue buffer (shorthand)")

	flag.Parse()

	// Check if output directory exists, create if it doesn't exist
	if _, err := os.Stat(outputDir); os.IsNotExist(err) {
		log.Printf("Output directory '%s' does not exist, creating...", outputDir)
		if err := os.MkdirAll(outputDir, 0755); err != nil {
			log.Fatalf("Failed to create output directory: %v", err)
		}
		log.Printf("Output directory created successfully")
	} else if err != nil {
		log.Fatalf("Failed to check output directory: %v", err)
	} else {
		log.Printf("Output directory '%s' already exists", outputDir)
	}
	// Create FileWriter with queue
	fileWriter := NewFileWriter(outputDir, queueSize)
	defer fileWriter.Close()

	// Start TCP server
	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatalf("Failed to start server on port %s: %v", port, err)
	}
	defer listener.Close()

	log.Printf("Server listening on port %s", port)
	log.Printf("Output directory: %s", outputDir)
	log.Printf("Write queue size: %d", queueSize)

	// Accept connections
	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("Failed to accept connection: %v", err)
			continue
		}

		// Handle connection in a goroutine
		go handleConnection(conn, fileWriter)
	}
}

func handleConnection(conn net.Conn, fileWriter *FileWriter) {
	defer conn.Close()

	clientAddr := conn.RemoteAddr().String()
	log.Printf("New connection from %s", clientAddr)

	// Create buffered reader for the connection
	reader := bufio.NewReader(conn)

	for {
		// Read data from connection
		data, err := reader.ReadBytes('\n')
		if err != nil {
			if err != io.EOF {
				log.Printf("Error reading from %s: %v", clientAddr, err)
			}
			break
		}

		// Remove trailing newline if present
		if len(data) > 0 && data[len(data)-1] == '\n' {
			data = data[:len(data)-1]
		}

		// Skip empty lines
		if len(data) == 0 {
			continue
		}

		// Queue data for writing
		fileWriter.QueueData(data, clientAddr)
	}

	log.Printf("Connection from %s closed", clientAddr)
}
