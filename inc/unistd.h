/*
 * Unix compatibility API - standard Unix "low-level" file I/O functions.
 * In PIOS, the "low-level" and "high-level" APIs actually refer to
 * the same set of file descriptors, just accessed slightly differently.
 *
 * Copyright (C) 2010 Yale University.
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Primary author: Bryan Ford
 */

#ifndef PIOS_INC_UNISTD_H
#define PIOS_INC_UNISTD_H 1

#include <types.h>
#include <cdefs.h>


#define STDIN_FILENO	0
#define STDOUT_FILENO	1
#define STDERR_FILENO	2

#ifndef SEEK_SET
#define SEEK_SET	0	/* seek relative to beginning of file */
#define SEEK_CUR	1	/* seek relative to current file position */
#define SEEK_END	2	/* seek relative to end of file */
#endif

// Exit status codes from wait() and waitpid().
// These are traditionally in <sys/wait.h>.
#define WEXITED			0x0100	// Process exited via exit()
#define WSIGNALED		0x0200	// Process exited via uncaught signal

#define WIFEXITED(x)		(((x) & 0xf00) == WEXITED)
#define WEXITSTATUS(x)		((x) & 0xff)
#define WIFSIGNALED(x)		(((x) & 0xf00) == WSIGNALED)
#define WTERMSIG(x)		((x) & 0xff)


// Process management functions
pid_t	fork(void);
pid_t	wait(int *status);				// trad. in sys/wait.h
pid_t	waitpid(pid_t pid, int *status, int options);	// trad. in sys/wait.h
int	execl(const char *path, const char *arg0, ...);
int	execv(const char *path, char *const argv[]);

// File management functions
int	open(const char *path, int flags, ...);		// trad. in fcntl.h
int	creat(const char *path, mode_t mode);		// trad. in fcntl.h
int	close(int fn);
ssize_t	read(int fn, void *buf, size_t nbytes);
ssize_t	write(int fn, const void *buf, size_t nbytes);
off_t	lseek(int fn, off_t offset, int whence);
int	dup(int oldfn);
int	dup2(int oldfn, int newfn);
int	truncate(const char *path, off_t newlength);
int	ftruncate(int fn, off_t newlength);
int	isatty(int fn);
int	remove(const char *path);
int	fsync(int fn);


// PIOS-specific thread fork/join functions
int	tfork(uint16_t child);
void	tjoin(uint16_t child);


#endif	// !PIOS_INC_UNISTD_H
