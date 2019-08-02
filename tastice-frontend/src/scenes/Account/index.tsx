import { useMutation, useQuery } from '@apollo/react-hooks';
import { Avatar, Button, createStyles, Grid, makeStyles, Paper, TextField, Theme, Typography } from '@material-ui/core';
import { deepPurple } from '@material-ui/core/colors';
import axios from 'axios';
import { Image } from 'cloudinary-react';
import React, { useCallback, useEffect, useState } from 'react';
import { useDropzone } from 'react-dropzone';
import { TextValidator, ValidatorForm } from 'react-material-ui-form-validator';
import useReactRouter from 'use-react-router';
import { ConfirmationDialog } from '../../components/ConfirmationDialog';
import { client } from '../../index';
import { DELETE_USER, ME, UPDATE_AVATAR, UPDATE_PASSWORD, UPDATE_USER } from '../../queries';
import { errorHandler, notificationHandler } from '../../utils';

const useStyles = makeStyles((theme: Theme) =>
    createStyles({
        paper: {
            marginTop: 30,
            maxWidth: 700,
            padding: theme.spacing(3, 2),
            margin: `${theme.spacing(1)}px auto`,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            alignContent: 'center',
        },
        Avatar: {
            marginLeft: 30,
            marginRight: 30,
            marginTop: 20,
            marginBottom: 15,
            width: 200,
            backgroundColor: deepPurple[500],
            height: 200,
        },
        container: {
            display: 'flex',
            flexWrap: 'wrap',
            flexDirection: 'column',
            alignItems: 'center',
            alignContent: 'center',
            justifyContent: 'center',
        },
        textField: {
            marginTop: 10,
        },
        button: {
            marginTop: 15,
            width: '30%',
        },
        form: {
            padding: theme.spacing(3, 0),
        },
        avatarInitials: {
            margin: 10,
            color: '#fff',
        },
        imageAvatar: {
            marginTop: 20,
        },
    }),
);

export const Account = ({ setToken }: Token): JSX.Element | null => {
    const me = useQuery(ME);
    const classes = useStyles();

    const [firstName, setFirstName] = useState('');
    const [lastName, setLastName] = useState('');
    const [email, setEmail] = useState('');
    const [newAvatarId, setNewAvatarId] = useState('');

    const [currentPassword, setCurrentPassword] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [newPasswordCheck, setNewPasswordCheck] = useState('');

    const { history } = useReactRouter();
    const [visible, setVisible] = useState(false);

    const [updateAvatar] = useMutation(UPDATE_AVATAR, {
        onError: errorHandler,
        refetchQueries: [{ query: ME }],
    });

    const [deleteUser] = useMutation(DELETE_USER, {
        onError: errorHandler,
        refetchQueries: [{ query: ME }],
    });

    const [updateUser] = useMutation(UPDATE_USER, {
        onError: errorHandler,
        refetchQueries: [{ query: ME }],
    });

    const [changePassword] = useMutation(UPDATE_PASSWORD, {
        onError: errorHandler,
    });

    const uploadPreset = process.env.REACT_APP_CLOUDINARY_UPLOAD_PRESET || 'demo';

    const onDrop = useCallback(async acceptedFiles => {
        const formData = new FormData();
        formData.append('file', acceptedFiles[0]);
        formData.append('upload_preset', uploadPreset);

        const response = await axios.post(
            `https://api.cloudinary.com/v1_1/${process.env.REACT_APP_CLOUDINARY_CLOUD_NAME}/image/upload`,
            formData,
        );

        setNewAvatarId(response.data.public_id);
    }, []);

    const { getRootProps, getInputProps } = useDropzone({ onDrop });

    useEffect(() => {
        if (me.data.me !== undefined && firstName === '') {
            setFirstName(me.data.me.firstName);
            setLastName(me.data.me.lastName);
            setEmail(me.data.me.email);
            setNewAvatarId(me.data.me.avatarId);
        }
    }, [me, firstName, lastName, email]);

    if (me.data.me === undefined) {
        return null;
    }

    const user = me.data.me;

    const handleUpdateUser = async (event: any): Promise<void> => {
        event.preventDefault();

        const result = await updateUser({
            variables: {
                id: user.id,
                firstName: firstName || user.firstName,
                lastName: lastName || user.lastName,
                email: email || user.email,
            },
        });

        if (newAvatarId) {
            await updateAvatar({
                variables: {
                    id: user.id,
                    avatarId: newAvatarId,
                },
            });
        }

        if (result) {
            notificationHandler({
                message: `User '${result.data.updateUser.firstName}' succesfully updated`,
                variant: 'success',
            });
        }
    };

    const handleDeleteUser = async (): Promise<void> => {
        setVisible(false);
        await deleteUser({
            variables: { id: user.id },
        });
        await client.clearStore();
        localStorage.clear();
        setToken(null);
        history.push('/');
    };

    const handlePasswordChange = async (): Promise<void> => {
        if (newPassword.length < 3) {
            notificationHandler({
                message: `The password can't be under three characters`,
                variant: 'error',
            });
        } else if (newPassword !== newPasswordCheck) {
            notificationHandler({
                message: `The given passwords don't match`,
                variant: 'error',
            });
            setNewPassword('');
            setNewPasswordCheck('');
        } else {
            const result = await changePassword({
                variables: {
                    id: user.id,
                    existingPassword: currentPassword,
                    password: newPassword,
                },
            });

            if (result) {
                notificationHandler({
                    message: `Password succesfully updated!`,
                    variant: 'success',
                });
                setCurrentPassword('');
                setNewPassword('');
                setNewPasswordCheck('');
            }
        }
    };

    const handleEmailChange = (event: React.ChangeEvent<HTMLInputElement>): void => setEmail(event.target.value);

    const handleLastNameChange = (event: React.ChangeEvent<HTMLInputElement>): void => setLastName(event.target.value);

    const handleFirstNameChange = (event: React.ChangeEvent<HTMLInputElement>): void =>
        setFirstName(event.target.value);

    return (
        <div>
            <Paper className={classes.paper}>
                <Typography variant="h4" component="h3" className={classes.textField}>
                    Edit Profile Settings
                </Typography>
                <div {...getRootProps()}>
                    <input {...getInputProps()} />
                    <Avatar alt="Avatar" className={classes.Avatar}>
                        {user.avatarId ? (
                            <Image
                                cloudName={process.env.REACT_APP_CLOUDINARY_CLOUD_NAME}
                                publicId={newAvatarId}
                                width="200"
                                crop="thumb"
                            ></Image>
                        ) : (
                            <Typography variant="h3" className={classes.avatarInitials}>
                                {firstName.charAt(0).toUpperCase()}
                                {lastName.charAt(0).toUpperCase()}
                            </Typography>
                        )}
                    </Avatar>
                </div>

                <ValidatorForm onSubmit={handleUpdateUser} className={classes.form} onError={errorHandler}>
                    <Grid container spacing={2} alignItems="center" justify="center">
                        <Grid item xs={12}>
                            <TextValidator
                                autoComplete="fname"
                                name="firstName"
                                variant="outlined"
                                required
                                fullWidth
                                id="firstName"
                                label="First Name"
                                autoFocus
                                validators={[]}
                                errorMessages={[]}
                                value={firstName}
                                onChange={handleFirstNameChange}
                            />
                        </Grid>
                        <Grid item xs={12}>
                            <TextValidator
                                variant="outlined"
                                required
                                fullWidth
                                id="lastName"
                                label="Last Name"
                                name="lastName"
                                autoComplete="lname"
                                validators={[]}
                                errorMessages={[]}
                                value={lastName}
                                onChange={handleLastNameChange}
                            />
                        </Grid>

                        <Grid item xs={12}>
                            <TextValidator
                                variant="outlined"
                                required
                                fullWidth
                                id="email"
                                label="Email Address"
                                name="email"
                                autoComplete="email"
                                validators={['isEmail']}
                                errorMessages={['The entered email is not valid']}
                                value={email}
                                onChange={handleEmailChange}
                            />
                        </Grid>

                        <Button
                            type="submit"
                            color="primary"
                            variant="contained"
                            className={classes.button}
                            onClick={handleUpdateUser}
                        >
                            Save changes
                        </Button>
                    </Grid>
                </ValidatorForm>

                <Typography variant="h5" component="h5" className={classes.textField}>
                    Change Password
                </Typography>

                <TextField
                    variant="outlined"
                    margin="normal"
                    required
                    fullWidth
                    name="password"
                    label="Current Password"
                    type="password"
                    autoComplete="current-password"
                    value={currentPassword}
                    onChange={({ target }): void => setCurrentPassword(target.value)}
                />
                <TextField
                    variant="outlined"
                    margin="normal"
                    required
                    fullWidth
                    name="newPassword"
                    label="New Password"
                    type="password"
                    value={newPassword}
                    onChange={({ target }): void => setNewPassword(target.value)}
                />
                <TextField
                    variant="outlined"
                    margin="normal"
                    required
                    fullWidth
                    name="newPasswordCheck"
                    label="Repeat New Password"
                    type="password"
                    value={newPasswordCheck}
                    onChange={({ target }): void => setNewPasswordCheck(target.value)}
                />

                <Button onClick={handlePasswordChange} variant="contained" color="primary" className={classes.button}>
                    Change password!
                </Button>

                <Button
                    variant="outlined"
                    color="secondary"
                    className={classes.button}
                    onClick={(): void => setVisible(true)}
                >
                    Delete User
                </Button>
            </Paper>

            <ConfirmationDialog
                visible={visible}
                setVisible={setVisible}
                description={'hei'}
                title={'Warning!'}
                content={'Are you sure you want to remove your account?'}
                onAccept={handleDeleteUser}
                declineButton={'Cancel'}
                acceptButton={'Yes'}
            />
        </div>
    );
};
