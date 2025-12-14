#ifndef SHARED_MEMORY_H
#define SHARED_MEMORY_H

#include <string>
#include <iostream>
#include <sys/mman.h>
#include <sys/stat.h>        /* For mode constants */
#include <fcntl.h>           /* For O_* constants */
#include <unistd.h>
#include <errno.h>
#include <cstring>

class SharedMemory {
private:
    std::string name;
    size_t size;
    int shm_fd;
    void* ptr;
    bool is_creator;

public:
    SharedMemory(const std::string& shm_name, size_t shm_size) 
        : name(shm_name), size(shm_size), shm_fd(-1), ptr(MAP_FAILED), is_creator(false) {}

    ~SharedMemory() {
        close();
    }

    // Create and initialize shared memory (Simulator side)
    bool create() {
        // Open shared memory object
        shm_fd = shm_open(name.c_str(), O_CREAT | O_RDWR, 0666);
        if (shm_fd == -1) {
            std::cerr << "SharedMemory: shm_open failed: " << strerror(errno) << std::endl;
            return false;
        }

        // Configure size
        if (ftruncate(shm_fd, size) == -1) {
            std::cerr << "SharedMemory: ftruncate failed: " << strerror(errno) << std::endl;
            return false;
        }

        // Map shared memory
        ptr = mmap(0, size, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
        if (ptr == MAP_FAILED) {
            std::cerr << "SharedMemory: mmap failed: " << strerror(errno) << std::endl;
            return false;
        }

        is_creator = true;
        // Initialize to 0
        std::memset(ptr, 0, size);
        return true;
    }

    // Open existing shared memory (Display side)
    bool open() {
        // Open shared memory object (Read Only for display, but flags flags need atomic write so Read/Write essentially)
        // Ideally display only reads video, but it needs to clear the 'ready' flag, so it needs Write access.
        shm_fd = shm_open(name.c_str(), O_RDWR, 0666);
        if (shm_fd == -1) {
            // It's expected to fail if simulator hasn't started yet
            return false;
        }

        // Map shared memory
        ptr = mmap(0, size, PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd, 0);
        if (ptr == MAP_FAILED) {
            std::cerr << "SharedMemory: mmap failed: " << strerror(errno) << std::endl;
            ::close(shm_fd);
            return false;
        }

        is_creator = false;
        return true;
    }

    void close() {
        if (ptr != MAP_FAILED) {
            munmap(ptr, size);
            ptr = MAP_FAILED;
        }
        if (shm_fd != -1) {
            ::close(shm_fd);
            shm_fd = -1;
        }
        if (is_creator) {
            shm_unlink(name.c_str());
            is_creator = false;
        }
    }

    void* getPtr() const {
        return ptr;
    }
};

#endif // SHARED_MEMORY_H
